require('app/styles/admin.sass')
{backboneFailure, genericFailure} = require 'core/errors'
errors = require 'core/errors'
RootView = require 'views/core/RootView'
template = require 'templates/admin'
AdministerUserModal = require 'views/admin/AdministerUserModal'
forms = require 'core/forms'
utils = require 'core/utils'

Campaigns = require 'collections/Campaigns'
Classroom = require 'models/Classroom'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
Courses = require 'collections/Courses'
LevelSessions = require 'collections/LevelSessions'
User = require 'models/User'
Users = require 'collections/Users'

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
    'click .classroom-progress-csv': 'onClickExportProgress'
    'click #clear-feature-mode-btn': 'onClickClearFeatureModeButton'

  getTitle: -> return $.i18n.t('account_settings.admin')

  initialize: ->
    if window.serverSession.amActually
      @amActually = new User({_id: window.serverSession.amActually})
      @amActually.fetch()
      @supermodel.trackModel(@amActually)
    @featureMode = window.serverSession.featureMode
    super()

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
    if userID = utils.getQueryVariable 'user'
      @openModalView new AdministerUserModal({}, userID)

  clearQueryParams: -> window.history.pushState({}, '', document.location.href.split('?')[0])

  stopSpying: ->
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
    userNameOrEmail = @$el.find('#espionage-name-or-email').val().toLowerCase()
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
    searchValue = @$el.find('#user-search').val()
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
            <button class='user-spy-button'>Spy</button>
            #{if new User(user).isTeacher() then "<button class='teacher-dashboard-button'>View Classes</button>" else ""}
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
    sessions = null
    users = null
    userMap = {}
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
      users = new Users()
      Promise.resolve($.when(users.fetchForClassroom(classroom)...))
    .then (models) =>
      userMap[user.id] = user for user in users.models
      sessions = new LevelSessions()
      Promise.resolve($.when(sessions.fetchForAllClassroomMembers(classroom)...))
    .then (models) =>
      userLevelPlaytimeMap = {}
      for session in sessions.models
        continue unless session.get('state')?.complete
        levelID = session.get('level').original
        userID = session.get('creator')
        userLevelPlaytimeMap[userID] ?= {}
        userLevelPlaytimeMap[userID][levelID] ?= {}
        userLevelPlaytimeMap[userID][levelID] = session.get('playtime')

      userPlaytimes = []
      for userID, user of userMap
        playtimes = [user.get('name') ? 'Anonymous']
        for level in courseLevels
          if userLevelPlaytimeMap[userID]?[level.levelID]?
            rawSeconds = parseInt(userLevelPlaytimeMap[userID][level.levelID])
            hours = Math.floor(rawSeconds / 60 / 60)
            minutes = Math.floor(rawSeconds / 60 - hours * 60)
            seconds = Math.round(rawSeconds - hours * 60 - minutes * 60)
            hours = "0#{hours}" if hours < 10
            minutes = "0#{minutes}" if minutes < 10
            seconds = "0#{seconds}" if seconds < 10
            playtimes.push "#{hours}:#{minutes}:#{seconds}"
          else
            playtimes.push 'Incomplete'
        userPlaytimes.push(playtimes)

      columnLabels = "Username"
      currentLevel = 1
      courseLabelIndexes = CS: 1, GD: 0, WD: 0
      lastCourseIndex = 1
      lastCourseLabel = 'CS1'
      for level in courseLevels
        unless level.courseIndex is lastCourseIndex
          currentLevel = 1
          lastCourseIndex = level.courseIndex
          acronym = switch
            when /game-dev/.test(level.courseSlug) then 'GD'
            when /web-dev/.test(level.courseSlug) then 'WD'
            else 'CS'
          lastCourseLabel = acronym + ++courseLabelIndexes[acronym]
        columnLabels += ",#{lastCourseLabel}.#{currentLevel++} #{level.slug}"
      csvContent = "data:text/csv;charset=utf-8,#{columnLabels}\n"
      for studentRow in userPlaytimes
        csvContent += studentRow.join(',') + "\n"
      csvContent = csvContent.substring(0, csvContent.length - 1)
      encodedUri = encodeURI(csvContent)
      window.open(encodedUri)
      $('.classroom-progress-csv').prop('disabled', false)

    .catch (error) ->
      $('.classroom-progress-csv').prop('disabled', false)
      console.error error
      throw error
