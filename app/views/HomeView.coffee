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

#  TODO: auto margin feature paragraphs

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
    'click #learn-more-link': 'onClickLearnMoreLink'
    'click .screen-thumbnail': 'onClickScreenThumbnail'
    'click #carousel-left': 'onLeftPressed'
    'click #carousel-right': 'onRightPressed'
    'click .request-quote': 'onClickRequestQuote'
    'click .logout-btn': 'logoutAccount'
    'click .profile-btn': 'onClickTrackEvent'
    'click .setup-class-btn': 'onClickSetupClass'
    'click .my-classes-btn': 'onClickTrackEvent'
    'click .my-courses-btn': 'onClickTrackEvent'
    'click .resource-btn': 'onClickResourceButton'
    'click a': 'onClickAnchor'

  shortcuts:
    'right': 'onRightPressed'
    'left': 'onLeftPressed'
    'esc': 'onEscapePressed'

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

  onClickLearnMoreLink: ->
    window.tracker?.trackEvent 'Homepage Click Learn More', category: 'Homepage', []
    @scrollToLink('#classroom-in-box-container')

  onClickRequestQuote: (e) ->
    @playSound 'menu-button-click'
    e.preventDefault()
    e.stopImmediatePropagation()
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Homepage', []
    if me.isTeacher()
      application.router.navigate '/teachers/update-account', trigger: true
    else
      application.router.navigate '/teachers/quote', trigger: true

  onClickSetupClass: (e) ->
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Homepage', []
    application.router.navigate("/teachers/classes", { trigger: true })

  onClickStudentButton: (e) ->
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Homepage', []
    @openModalView(new CreateAccountModal({startOnPath: 'student'}))

  onClickTeacherButton: (e) ->
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Homepage', []
    @openModalView(new CreateAccountModal({startOnPath: 'teacher'}))

  onClickTrackEvent: (e) ->
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Homepage', []

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
      window.tracker?.trackEvent "Link: #{anchorText}", category: 'Homepage', ['Google Analytics']

  afterRender: ->
    require.ensure(['@vimeo/player'], (require) =>
      Player = require('@vimeo/player').default
      @vimeoPlayer = new Player(@$('.vimeo-player')[0])
    , (e) =>
      console.error e
    , 'vimeo')
    @$('#screenshot-lightbox')
      .modal()
      .on 'hide.bs.modal', (e)=>
        @vimeoPlayer.pause()
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

  onRightPressed: (event) ->
    # Special handling, otherwise after you click the control, keyboard presses move the slide twice
    return if event.type is 'keydown' and $(document.activeElement).is('.carousel-control')
    if $('#screenshot-lightbox').data('bs.modal')?.isShown
      event.preventDefault()
      $('#screenshot-carousel').carousel('next')

  onLeftPressed: (event) ->
    return if event.type is 'keydown' and $(document.activeElement).is('.carousel-control')
    if $('#screenshot-lightbox').data('bs.modal')?.isShown
      event.preventDefault()
      $('#screenshot-carousel').carousel('prev')

  onEscapePressed: (event) ->
    if $('#screenshot-lightbox').data('bs.modal')?.isShown
      event.preventDefault()
      $('#screenshot-lightbox').modal('hide')

  onClickScreenThumbnail: (event) ->
    unless $('#screenshot-lightbox').data('bs.modal')?.isShown
      event.preventDefault()
      # Modal opening happens automatically from bootstrap
      $('#screenshot-carousel').carousel($(event.currentTarget).data("index"))

  mergeWithPrerendered: (el) ->
    true
