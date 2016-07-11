{backboneFailure, genericFailure} = require 'core/errors'
errors = require 'core/errors'
RootView = require 'views/core/RootView'
template = require 'templates/admin'
AdministerUserModal = require 'views/admin/AdministerUserModal'
forms = require 'core/forms'

Campaigns = require 'collections/Campaigns'
Classroom = require 'models/Classroom'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
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
    'click #user-search-result': 'onClickUserSearchResult'
    'click #create-free-sub-btn': 'onClickFreeSubLink'
    'click #terminal-create': 'onClickTerminalSubLink'
    'click .classroom-progress-csv': 'onClickExportProgress'

  getTitle: -> return $.i18n.t('account_settings.admin')

  initialize: ->
    if window.amActually
      @amActually = new User({_id: window.amActually})
      @amActually.fetch()
      @supermodel.trackModel(@amActually)
    super()

  onClickStopSpyingButton: ->
    button = @$('#stop-spying-btn')
    forms.disableSubmit(button)
    me.stopSpying({
      success: -> document.location.reload()
      error: ->
        forms.enableSubmit(button)
        errors.showNotyNetworkError(arguments...)
    })

  onSubmitEspionageForm: (e) ->
    e.preventDefault()
    button = @$('#enter-espionage-mode')
    userNameOrEmail = @$el.find('#espionage-name-or-email').val().toLowerCase()
    forms.disableSubmit(button)
    me.spy(userNameOrEmail, {
      success: -> window.location.reload()
      error: ->
        forms.enableSubmit(button)
        errors.showNotyNetworkError(arguments...)
    })

  onSubmitUserSearchForm: (e) ->
    e.preventDefault()
    searchValue = @$el.find('#user-search').val()
    return if searchValue is @lastUserSearchValue
    return @onSearchRequestSuccess [] unless @lastUserSearchValue = searchValue.toLowerCase()
    forms.disableSubmit(@$('#user-search-button'))
    $.ajax
      type: 'POST',
      url: '/db/user/-/admin_search'
      data: {search: @lastUserSearchValue}
      success: @onSearchRequestSuccess
      error: @onSearchRequestFailure

  onSearchRequestSuccess: (users) =>
    forms.enableSubmit(@$('#user-search-button'))
    result = ''
    if users.length
      result = ("<tr data-user-id='#{user._id}'><td><code>#{user._id}</code></td><td>#{_.escape(user.name or 'Anonymous')}</td><td>#{_.escape(user.email)}</td></tr>" for user in users)
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

  onClickExportProgress: ->
    $('.classroom-progress-csv').prop('disabled', true)
    classCode = $('.classroom-progress-class-code').val()
    classroom = null
    courseLevels = []
    sessions = null
    users = null
    userMap = {}
    Promise.resolve(new Classroom().fetchByCode(classCode))
    .then (model) =>
      classroom = new Classroom({ _id: model.data._id })
      Promise.resolve(classroom.fetch())
    .then (model) =>
      for course, index in classroom.get('courses')
        for level in course.levels
          courseLevels.push
            courseIndex: index + 1
            levelID: level.original
            slug: level.slug
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
      lastCourseIndex = 1
      for level in courseLevels
        unless level.courseIndex is lastCourseIndex
          currentLevel = 1
          lastCourseIndex = level.courseIndex
        columnLabels += ",CS#{level.courseIndex}.#{currentLevel++} #{level.slug}"
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
