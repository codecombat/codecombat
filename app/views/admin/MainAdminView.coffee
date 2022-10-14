require('app/styles/admin.sass')
{backboneFailure, genericFailure} = require 'core/errors'
errors = require 'core/errors'
RootView = require 'views/core/RootView'
template = require 'app/templates/admin'
AdministerUserModal = require 'views/admin/AdministerUserModal'
MaintenanceModal = require 'views/admin/MaintenanceModal'
TeacherLicenseCodeModal = require 'views/admin/TeacherLicenseCodeModal'
ModelModal = require 'views/modal/ModelModal'
forms = require 'core/forms'
utils = require 'core/utils'
{ updateAvailabilityStatus } = require 'core/api/parents'

Campaigns = require 'collections/Campaigns'
Classroom = require 'models/Classroom'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
Courses = require 'collections/Courses'
LevelSessions = require 'collections/LevelSessions'
InteractiveSessions = require 'collections/InteractiveSessions'
Prepaid = require 'models/Prepaid'
User = require 'models/User'
Users = require 'collections/Users'
Mandate = require 'models/Mandate'
window.saveAs ?= require 'file-saver/FileSaver.js' # `window.` is necessary for spec to spy on it
window.saveAs = window.saveAs.saveAs if window.saveAs.saveAs  # Module format changed with webpack?

module.exports = class MainAdminView extends RootView
  id: 'admin-view'
  template: template
  lastUserSearchValue: ''

  events:
    'submit #espionage-form': 'onSubmitEspionageForm'
    'submit #user-search-form': 'onSubmitUserSearchForm'
    'click #stop-spying-btn': 'onClickStopSpyingButton'
    'click #increment-button': 'incrementUserAttribute'
    'click .user-spy-button': 'onClickUserSpyButton'
    'click .teacher-dashboard-button': 'onClickTeacherDashboardButton'
    'click #user-search-result': 'onClickUserSearchResult'
    'click #create-free-sub-btn': 'onClickFreeSubLink'
    'click #terminal-create': 'onClickTerminalSubLink'
    'click #terminal-activation-create': 'onClickTerminalActivationLink'
    'click .classroom-progress-csv': 'onClickExportProgress'
    'click #clear-feature-mode-btn': 'onClickClearFeatureModeButton'
    'click .edit-mandate': 'onClickEditMandate'
    'click #maintenance-mode': 'onClickMaintenanceMode'
    'click #teacher-license-code': 'onClickTeacherLicenseCode'
    'click #toggle-admin-availability': 'onClickToggleAdminAvailability'

  getTitle: -> return $.i18n.t('account_settings.admin')

  initialize: ->
    if window.serverSession.amActually
      @amActually = new User({_id: window.serverSession.amActually})
      @amActually.fetch()
      @supermodel.trackModel(@amActually)
    @featureMode = window.serverSession.featureMode
    @timeZone = if features?.chinaInfra then 'Asia/Shanghai' else 'America/Los_Angeles'
    super()

  getRenderData: (context={}) ->
    context = super context
    context.parentAdminAvailabilityStatus = @parentAdminAvailabilityStatus or 'on'
    context.parentAdminUpdateInProgress = @parentAdminUpdateInProgress or false
    context

  afterInsert: ->
    super()
    if search = utils.getQueryVariable 'search'
      $('#user-search').val search
      $('#user-search-button').click()
    if spy = utils.getQueryVariable 'spy'
      if @amActually
        @stopSpying()
      else
        $('#espionage-name-or-email').val spy
        $('#enter-espionage-mode').click()
    if (me.isAdmin() or me.isOnlineTeacher()) and userID = utils.getQueryVariable 'user'
      @openModalView new AdministerUserModal({}, userID)

  clearQueryParams: -> window.history.pushState({}, '', document.location.href.split('?')[0])

  stopSpying: ->
    button = @$('#stop-spying-btn')
    me.stopSpying({
      success: -> document.location.reload()
      error: ->
        forms.enableSubmit(button)
        errors.showNotyNetworkError(arguments...)
    })

  onClickStopSpyingButton: ->
    button = @$('#stop-spying-btn')
    forms.disableSubmit(button)
    @clearQueryParams()
    @stopSpying()

  onClickClearFeatureModeButton: (e) ->
    e.preventDefault()
    application.featureMode.clear()

  onSubmitEspionageForm: (e) ->
    e.preventDefault()
    button = @$('#enter-espionage-mode')
    userNameOrEmail = @$el.find('#espionage-name-or-email').val().toLowerCase().trim()
    forms.disableSubmit(button)
    @clearQueryParams()
    me.spy(userNameOrEmail, {
      success: -> window.location.reload()
      error: ->
        forms.enableSubmit(button)
        errors.showNotyNetworkError(arguments...)
    })

  onClickUserSpyButton: (e) ->
    e.stopPropagation()
    userID = $(e.target).closest('tr').data('user-id')
    button = $(e.currentTarget)
    forms.disableSubmit(button)
    me.spy(userID, {
      success: -> window.location.reload()
      error: ->
        forms.enableSubmit(button)
        errors.showNotyNetworkError(arguments...)
    })

  onClickTeacherDashboardButton: (e) ->
    e.stopPropagation()
    userID = $(e.target).closest('tr').data('user-id')
    button = $(e.currentTarget)
    forms.disableSubmit(button)
    url = "/teachers/classes?teacherID=#{userID}"
    application.router.navigate(url, { trigger: true })

  onSubmitUserSearchForm: (e) ->
    e.preventDefault()
    searchValue = @$el.find('#user-search').val().trim()
    return if searchValue is @lastUserSearchValue
    return @onSearchRequestSuccess [] unless @lastUserSearchValue = searchValue.toLowerCase()
    forms.disableSubmit(@$('#user-search-button'))
    q = @lastUserSearchValue
    role = undefined
    q = q.replace /role:([^ ]+)/, (dummy, m1) ->
      role = m1
      return ''

    data = {adminSearch: q}
    data.role = role if role?
    $.ajax
      type: 'GET',
      url: '/db/user'
      data: data
      success: @onSearchRequestSuccess
      error: @onSearchRequestFailure

  onSearchRequestSuccess: (users) =>
    forms.enableSubmit(@$('#user-search-button'))
    result = ''
    if users.length
      result = []
      for user in users
        if user._trialRequest
          trialRequestBit = "<br/>#{user._trialRequest.nces_name or user._trialRequest.organization} / #{user._trialRequest.nces_district || user._trialRequest.district}"
        else
          trialRequestBit = ""

        result.push("
        <tr data-user-id='#{user._id}'>
          <td><code>#{user._id}</code></td>
          <td>#{user.role or ''}</td>
          <td><img src='/db/user/#{user._id}/avatar?s=18' class='avatar'> #{_.escape(user.name or 'Anonymous')}</td>
          <td>#{_.escape(user.email)}#{trialRequestBit}</td>
          <td>#{user.firstName or ''}</td>
          <td>#{user.lastName or ''}</td>
          <td>
            #{if me.isAdmin() then "<button class='user-spy-button'>Spy</button>" else ""}
            <!-- New Teacher Dashboard doesn't allow admin to navigate to a teacher classroom. -->
            #{if new User(user).isTeacher() and not utils.isOzaria then "<button class='teacher-dashboard-button'>View Classes</button>" else ""}
          </td>
        </tr>")
      result = "<table class=\"table\">#{result.join('\n')}</table>"
    @$el.find('#user-search-result').html(result)

  onSearchRequestFailure: (jqxhr, status, error) =>
    return if @destroyed
    forms.enableSubmit(@$('#user-search-button'))
    console.warn "There was an error looking up #{@lastUserSearchValue}:", error

  incrementUserAttribute: (e) ->
    val = $('#increment-field').val()
    me.set(val, me.get(val) + 1)
    me.save()

  onClickUserSearchResult: (e) ->
    userID = $(e.target).closest('tr').data('user-id')
    @openModalView new AdministerUserModal({}, userID) if userID

  onClickFreeSubLink: (e) =>
    delete @freeSubLink
    return unless me.isAdmin()
    options =
      url: '/db/prepaid/-/create'
      data: {type: 'subscription', maxRedeemers: 1}
      method: 'POST'
    options.success = (model, response, options) =>
      # TODO: Don't hardcode domain.
      if application.isProduction()
        @freeSubLink = "https://codecombat.com/account/subscription?_ppc=#{model.code}"
      else
        @freeSubLink = "http://localhost:3000/account/subscription?_ppc=#{model.code}"
      @render?()
    options.error = (model, response, options) =>
      console.error 'Failed to create prepaid', response
    @supermodel.addRequestResource('create_prepaid', options, 0).load()

  onClickToggleAdminAvailability: (e) =>
    if @parentAdminUpdateInProgress
      return

    status = $(e.target).data('value')
    @parentAdminUpdateInProgress = true
    @parentAdminAvailabilityStatus = status
    @render?()

    updateAvailabilityStatus(status)
    .then (response) =>
      @parentAdminUpdateInProgress = false
      @parentAdminAvailabilityStatus = response.status
      noty({ text: "Status successfully updated to \"#{response.status}\"", layout: 'topCenter', type: 'success', timeout: 3000 })
    .catch (e) =>
      noty({ text: 'Status save failure: ' + e, layout: 'topCenter', type: 'error', timeout: 3000 })
      @parentAdminUpdateInProgress = false
    .finally () =>
      @render?()

  onClickTerminalSubLink: (e) =>
    @freeSubLink = ''
    return unless me.isAdmin()

    options =
      url: '/db/prepaid/-/create'
      method: 'POST'
      data:
        type: 'terminal_subscription'
        maxRedeemers: parseInt($("#users").val())
        months: parseInt($("#months").val())

    options.success = (model, response, options) =>
      # TODO: Don't hardcode domain.
      if application.isProduction()
        @freeSubLink = "https://codecombat.com/account/prepaid?_ppc=#{model.code}"
      else
        @freeSubLink = "http://localhost:3000/account/prepaid?_ppc=#{model.code}"
      @render?()
    options.error = (model, response, options) =>
      console.error 'Failed to create prepaid', response
    @supermodel.addRequestResource('create_prepaid', options, 0).load()

  onClickTerminalActivationLink: (e) =>
    return unless me.isAdmin()
    attrs =
      type: 'terminal_subscription'
      creator: me.id
      maxRedeemers: parseInt($("#users").val())
      generateActivationCodes: true
      endDate: $("#endDate").val() + ' ' + "23:59"
      properties:
        months: parseInt($("#months").val())
    prepaid = new Prepaid(attrs)
    prepaid.save(0)
    @listenTo prepaid, 'sync', ->
      csvContent = 'Code,Months,Expires\n'
      ocode = prepaid.get('code').toUpperCase()
      months = prepaid.get('properties').months
      for code in prepaid.get('redeemers')
        csvContent += "#{ocode.slice(0, 4)}-#{code.code.toUpperCase()}-#{ocode.slice(4)},#{months},#{code.date}\n"
      file = new Blob([csvContent], {type: 'text/csv;charset=utf-8'})
      window.saveAs(file, 'ActivationCodes.csv')

  afterRender: ->
    super()
    @$el.find('.search-help-toggle').click () =>
      @$el.find('.search-help').toggle()

  onClickExportProgress: ->
    $('.classroom-progress-csv').prop('disabled', true)
    classCode = $('.classroom-progress-class-code').val()
    classroom = null
    courses = null
    courseLevels = []
    courseInteractives = []
    sessions = null
    interactiveSessions = null
    users = null
    userMap = {}
    userLevelPlaytimeMap = {}
    Promise.resolve(new Classroom().fetchByCode(classCode))
    .then (model) =>
      classroom = new Classroom({ _id: model.data._id })
      Promise.resolve(classroom.fetch())
    .then (model) =>
      courses = new Courses()
      Promise.resolve(courses.fetch())
    .then (models) =>
      for course, index in classroom.get('courses')
        for level in course.levels
          courseLevels.push
            courseIndex: index + 1
            levelID: level.original
            slug: level.slug
            courseSlug: courses.get(course._id).get('slug')
          for intro in level.introContent ? [] when intro.type is 'interactive'
            # TODO: this only works for Python presently
            courseInteractives.push
              courseIndex: index + 1
              interactiveID: intro.contentId.python ? intro.contentId
              courseSlug: courses.get(course._id).get('slug')
      users = new Users()
      Promise.resolve($.when(users.fetchForClassroom(classroom)...))
    .then (models) =>
      userMap[user.id] = user for user in users.models
      sessions = new LevelSessions()
      Promise.resolve($.when(sessions.fetchForAllClassroomMembers(classroom)...))
    .then (models) =>
      for session in sessions.models
        continue unless session.get('state')?.complete
        levelID = session.get('level').original
        userID = session.get('creator')
        userLevelPlaytimeMap[userID] ?= {}
        userLevelPlaytimeMap[userID][levelID] ?= {}
        if session.get('contentPlaytimes')
          playtime = 0
          playtime += content.playtime ? 0 for content in session.get('contentPlaytimes')
        else
          playtime = session.get('playtime')
        userLevelPlaytimeMap[userID][levelID] = playtime
      interactiveSessions = new InteractiveSessions()
      if utils.isOzaria
        Promise.resolve($.when(interactiveSessions.fetchForAllClassroomMembers(classroom)...))
      else
        Promise.resolve([])  # No interactives in CodeCombat yet
    .then (models) =>
      userInteractiveAttemptMap = {}
      for session in interactiveSessions.models
        continue unless session.get('complete')
        interactiveID = session.get('interactiveId')
        userID = session.get('userId')
        userInteractiveAttemptMap[userID] ?= {}
        userInteractiveAttemptMap[userID][interactiveID] ?= {}
        userInteractiveAttemptMap[userID][interactiveID] = session.get('submissionCount')

      userRows = []
      for userID, user of userMap
        row = [user.get('name') ? 'Anonymous']
        for level in courseLevels
          if userLevelPlaytimeMap[userID]?[level.levelID]?
            rawSeconds = parseInt(userLevelPlaytimeMap[userID][level.levelID])
            if false
              # Old way, with human-readable times
              hours = Math.floor(rawSeconds / 60 / 60)
              minutes = Math.floor(rawSeconds / 60 - hours * 60)
              seconds = Math.round(rawSeconds - hours * 60 - minutes * 60)
              hours = "0#{hours}" if hours < 10
              minutes = "0#{minutes}" if minutes < 10
              seconds = "0#{seconds}" if seconds < 10
              row.push "#{hours}:#{minutes}:#{seconds}"
            else
              # New way, with machine-analyzable times (seconds)
              row.push Math.round(rawSeconds)
          else
            row.push 'Incomplete'

        for interactive in courseInteractives
          attempts = userInteractiveAttemptMap[userID]?[interactive.interactiveID]
          if attempts
            row.push attempts
          else
            row.push 'Incomplete'

        userRows.push(row)

      columnLabels = "Username"
      currentLevel = 1
      courseLabelIndexes = CS: 1, GD: 0, WD: 0, CH: 1
      lastCourseIndex = 1
      lastCourseLabel = if utils.isOzaria then 'CH1' else 'CS1'
      for level in courseLevels
        unless level.courseIndex is lastCourseIndex
          currentLevel = 1
          lastCourseIndex = level.courseIndex
          acronym = switch
            when /game-dev/.test(level.courseSlug) then 'GD'
            when /web-dev/.test(level.courseSlug) then 'WD'
            when /chapter/.test(level.courseSlug) then 'CH'
            else 'CS'
          lastCourseLabel = acronym + ++courseLabelIndexes[acronym]
        columnLabels += ",#{lastCourseLabel}.#{currentLevel++} #{level.slug}"
      currentInteractive = 1
      courseLabelIndexes.CH = 1
      lastCourseIndex = 1
      lastCourseLabel = 'CH1'
      for interactive in courseInteractives
        unless interactive.courseIndex is lastCourseIndex
          currentInteractive = 1
          lastCourseIndex = interactive.courseIndex
          acronym = 'CH'
          lastCourseLabel = acronym + ++courseLabelIndexes[acronym]
        columnLabels += ",#{lastCourseLabel}.#{currentInteractive++} #{interactive.interactiveID}"
      csvContent = "data:text/csv;charset=utf-8,#{columnLabels}\n"
      for studentRow in userRows
        csvContent += studentRow.join(',') + "\n"
      csvContent = csvContent.substring(0, csvContent.length - 1)
      encodedUri = encodeURI(csvContent)
      window.open(encodedUri)
      $('.classroom-progress-csv').prop('disabled', false)

    .catch (error) ->
      $('.classroom-progress-csv').prop('disabled', false)
      console.error error
      throw error

  onClickEditMandate: (e) ->
    @mandate ?= @supermodel.loadModel(new Mandate()).model
    if @mandate.loaded
      @editMandate @mandate
    else
      @listenTo @mandate, 'sync', @editMandate

  onClickMaintenanceMode: (e) ->
    @openModalView? new MaintenanceModal() if me.isAdmin()

  onClickTeacherLicenseCode: (e) ->
    @openModalView? new TeacherLicenseCodeModal() if me.isAdmin()

  editMandate: (mandate) =>
    mandate = new Mandate _id: mandate.get('0')._id  # Work around weirdness in this actually being a singleton
    @openModalView? new ModelModal models: [mandate]
