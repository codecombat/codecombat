require('app/styles/home-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/home-view'
CocoCollection = require 'collections/CocoCollection'
TrialRequest = require 'models/TrialRequest'
TrialRequests = require 'collections/TrialRequests'
Courses = require 'collections/Courses'
utils = require 'core/utils'
storage = require 'core/storage'
{logoutUser, me} = require('core/auth')
CreateAccountModal = require 'views/core/CreateAccountModal/CreateAccountModal'

module.exports = class HomeView extends RootView
  id: 'home-view'
  template: template

  events:
    'click .continue-playing-btn': 'onClickTrackEvent'
    'click .example-gd-btn': 'onClickTrackEvent'
    'click .example-wd-btn': 'onClickTrackEvent'
    'click .play-btn': 'onClickTrackEvent'
    'click .signup-home-btn': 'onClickTrackEvent'
    'click .student-btn': 'onClickStudentButton'
    'click .teacher-btn': 'onClickTeacherButton'
    'click .request-quote': 'onClickRequestQuote'
    'click .logout-btn': 'logoutAccount'
    'click .profile-btn': 'onClickTrackEvent'
    'click .setup-class-btn': 'onClickSetupClass'
    'click .my-classes-btn': 'onClickTrackEvent'
    'click .my-courses-btn': 'onClickTrackEvent'
    'click a': 'onClickAnchor'

  initialize: (options) ->
    @courses = new Courses()
    @supermodel.trackRequest @courses.fetchReleased()

    if me.isTeacher()
      @trialRequests = new TrialRequests()
      @trialRequests.fetchOwn()
      @supermodel.loadCollection(@trialRequests)

  onLoaded: ->
    @trialRequest = @trialRequests.first() if @trialRequests?.size()
    @isTeacherWithDemo = @trialRequest and @trialRequest.get('status') in ['approved', 'submitted']
    super()

  onClickRequestQuote: (e) ->
    @playSound 'menu-button-click'
    e.preventDefault()
    e.stopImmediatePropagation()
    @homePageEvent($(e.target).data('event-action'))
    if me.isTeacher()
      application.router.navigate '/teachers/update-account', trigger: true
    else
      application.router.navigate '/teachers/quote', trigger: true

  onClickSetupClass: (e) ->
    @homePageEvent($(e.target).data('event-action'))
    application.router.navigate("/teachers/classes", { trigger: true })

  onClickStudentButton: (e) ->
    @homePageEvent($(e.target).data('event-action'))
    @openModalView(new CreateAccountModal({startOnPath: 'student'}))

  onClickTeacherButton: (e) ->
    @homePageEvent($(e.target).data('event-action'))
    @openModalView(new CreateAccountModal({startOnPath: 'teacher'}))

  onClickTrackEvent: (e) ->
    @homePageEvent($(e.target).data('event-action'))

  # Provides a uniform interface for collecting information from the homepage.
  # Always provides the category Homepage and includes the user role.
  homePageEvent: (action, extraproperties={}, includeIntegrations=[]) ->
    defaults =
      category: 'Homepage'
      user: me.get('role') || (me.isAnonymous() && "anonymous") || "homeuser"
    properties = _.merge(defaults, extraproperties)

    window.tracker?.trackEvent(
        action,
        properties,
        includeIntegrations )

  onClickAnchor: (e) ->
    return unless anchor = e?.currentTarget
    # Track an event with action of the English version of the link text
    translationKey = $(anchor).attr('data-i18n')
    translationKey ?= $(anchor).children('[data-i18n]').attr('data-i18n')
    if translationKey
      anchorText = $.i18n.t(translationKey, {lng: 'en-US'})
    else
      anchorText = anchor.text
    if anchorText
      @homePageEvent("Link: #{anchorText}", {}, ['Google Analytics'])
    else
      @homePageEvent("Link:", {clicked: e?.currentTarget?.host or "unknown"}, ['Google Analytics'])

  afterRender: ->
    require.ensure(['@vimeo/player'], (require) =>
      Player = require('@vimeo/player').default
      @vimeoPlayer = new Player(@$('.vimeo-player')[0])
    , (e) =>
      console.error e
    , 'vimeo')
    if me.isAnonymous()
      if document.location.hash is '#create-account'
        @openModalView(new CreateAccountModal())
      if document.location.hash is '#create-account-individual'
        @openModalView(new CreateAccountModal({startOnPath: 'individual'}))
      if document.location.hash is '#create-account-student'
        @openModalView(new CreateAccountModal({startOnPath: 'student'}))
      if document.location.hash is '#create-account-teacher'
        @openModalView(new CreateAccountModal({startOnPath: 'teacher'}))
    super()

  afterInsert: ->
    super()
    # scroll to the current hash, once everything in the browser is set up
    f = =>
      return if @destroyed
      link = $(document.location.hash)
      if link.length
        @scrollToLink(document.location.hash, 0)
    _.delay(f, 100)

  logoutAccount: ->
    Backbone.Mediator.publish("auth:logging-out", {})
    logoutUser()

  mergeWithPrerendered: (el) ->
    true
