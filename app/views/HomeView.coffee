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
EducatorSignupOzariaEncouragementModal = require('app/views/teachers/EducatorSignupOzariaEncouragementModal').default

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
    'click .parent-btn': 'onClickParentButton'
    'click .request-quote': 'onClickRequestQuote'
    'click .logout-btn': 'logoutAccount'
    'click .profile-btn': 'onClickTrackEvent'
    'click .setup-class-btn': 'onClickSetupClass'
    'click .my-classes-btn': 'onClickTrackEvent'
    'click .my-courses-btn': 'onClickTrackEvent'
    'click .try-ozaria': 'onClickTrackEvent'
    'click a': 'onClickAnchor'

  initialize: (options) ->
    super(options)

    @courses = new Courses()
    @supermodel.trackRequest @courses.fetchReleased()

    if me.isTeacher()
      @trialRequests = new TrialRequests()
      @trialRequests.fetchOwn()
      @supermodel.loadCollection(@trialRequests)

    @renderedPaymentNoty = false

  getMeta: ->
    title: $.i18n.t 'new_home.title'
    meta: [
        { vmid: 'meta-description', name: 'description', content: $.i18n.t 'new_home.meta_description' }
    ],
    link: [
      { vmid: 'rel-canonical', rel: 'canonical', href: '/'  }
    ]

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
    @homePageEvent('Started Signup')
    @homePageEvent($(e.target).data('event-action'))
    @openModalView(new CreateAccountModal({startOnPath: 'student'}))

  onClickTeacherButton: (e) ->
    @homePageEvent($(e.target).data('event-action'))
    @openEducatorSignupOzariaEncouragementModal(() =>
      @homePageEvent('Started Signup')
      @openModalView(new CreateAccountModal({startOnPath: 'teacher'}))
    )

  onClickParentButton: (e) ->
    @homePageEvent($(e.target).data('event-action'))
    application.router.navigate '/parents', trigger: true

  openEducatorSignupOzariaEncouragementModal: (onNext) ->
    # The modal container needs to exist outside of $el because the loading screen swap deletes the holder element
    if @ozariaEncouragementModalContainer
      @ozariaEncouragementModalContainer.remove()

    @ozariaEncouragementModalContainer = document.createElement('div')
    document.body.appendChild(@ozariaEncouragementModalContainer)

    @ozariaEncouragementModal = new EducatorSignupOzariaEncouragementModal({
      el: @ozariaEncouragementModalContainer,
      propsData: {
        onNext: onNext
      }
    })

  cleanupEncouragementModal: ->
    if @ozariaEncouragementModal
      @ozariaEncouragementModal.$destroy()
      @ozariaEncouragementModalContainer.remove()

  onClickTrackEvent: (e) ->
    if $(e.target)?.hasClass('track-ab-result')
      properties = {trackABResult: true}
    @homePageEvent($(e.target).data('event-action'), properties || {})

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

    if $(e.target)?.hasClass('track-ab-result')
      properties = {trackABResult: true}

    if anchorText
      @homePageEvent("Link: #{anchorText}", properties || {}, ['Google Analytics'])
    else
      _.extend(properties || {}, {
        clicked: e?.currentTarget?.host or "unknown"
      })
      @homePageEvent("Link:", properties, ['Google Analytics'])

  afterRender: ->
    vimeoPlayerIframe = @$('.vimeo-player')[0]
    if !me.showChinaVideo() and vimeoPlayerIframe
      require.ensure(['@vimeo/player'], (require) =>
        Player = require('@vimeo/player').default
        @vimeoPlayer = new Player(vimeoPlayerIframe)
      , (e) =>
        console.error e
      , 'vimeo')

    if me.isAnonymous()
      if document.location.hash is '#create-account' or utils.getQueryVariable('registering') == true
        @openModalView(new CreateAccountModal())
      if document.location.hash is '#create-account-individual'
        @openModalView(new CreateAccountModal({startOnPath: 'individual'}))
      if document.location.hash is '#create-account-student'
        @openModalView(new CreateAccountModal({startOnPath: 'student'}))
      if document.location.hash is '#create-account-teacher'
        @openModalView(new CreateAccountModal({startOnPath: 'teacher'}))

    if utils.getQueryVariable('payment-studentLicenses') in ['success', 'failed'] and not @renderedPaymentNoty
      paymentResult = utils.getQueryVariable('payment-studentLicenses')
      if paymentResult is 'success'
        title = $.i18n.t 'payments.studentLicense_successful'
        type = 'success'
      else
        title = $.i18n.t 'payments.failed'
        type = 'error'
      noty({ text: title, type: type, timeout: 10000, killer: true })
      @renderedPaymentNoty = true
    else if utils.getQueryVariable('payment-onlineClasses') in ['success', 'failed'] and not @renderedPaymentNoty
      paymentResult = utils.getQueryVariable('payment-onlineClasses')
      if paymentResult is 'success'
        title = $.i18n.t 'payments.onlineClasses_successful'
        type = 'success'
      else
        title = $.i18n.t 'payments.failed'
        type = 'error'
      noty({ text: title, type: type, timeout: 10000, killer: true })
      @renderedPaymentNoty = true
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

  destroy: ->
   @cleanupEncouragementModal()
   super()

  mergeWithPrerendered: (el) ->
    true
