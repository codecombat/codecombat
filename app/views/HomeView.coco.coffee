require('app/styles/home-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/home-view'
CocoCollection = require 'collections/CocoCollection'
utils = require 'core/utils'
storage = require 'core/storage'
{logoutUser, me} = require('core/auth')
CreateAccountModal = require 'views/core/CreateAccountModal/CreateAccountModal'
GetStartedSignupModal  = require('app/views/teachers/GetStartedSignupModal').default
paymentUtils = require 'app/lib/paymentUtils'

module.exports = class HomeView extends RootView
  id: 'home-view'
  template: template

  events:
    'click .continue-playing-btn': 'onClickTrackEvent'
    'click .student-btn': 'onClickStudentButton'
    'click .teacher-btn': 'onClickTeacherButton'
    'click .parent-btn': 'onClickParentButton'
    'click .my-classes-btn': 'onClickTrackEvent'
    'click .my-courses-btn': 'onClickTrackEvent'
    'click .try-ozaria': 'onClickTrackEvent'
    'click .product-btn a': 'onClickTrackEvent'
    'click .product-btn button': 'onClickTrackEvent'
    'click a': 'onClickAnchor'
    'click .get-started-btn': 'onClickGetStartedButton'
    'click .create-account-teacher-btn': 'onClickCreateAccountTeacherButton'
    'click .carousel-dot': 'onCarouselDirectMove'
    'click .carousel-tab': 'onCarouselDirectMovev2'

  initialize: (options) ->
    super(options)
    @renderedPaymentNoty = false

  getRenderData: (context={}) ->
    context = super context
    context.maintenanceStartTime = moment('2022-05-07T16:00:00-07:00')
    context.i18nData =
      slides: "<a href='https://docs.google.com/presentation/d/1KgFOg2tqbKEH8qNwIBdmK2QbHvTsxnW_Xo7LvjPsxwE/edit?usp=sharing' target='_blank'>#{$.i18n.t('new_home.lesson_slides')}</a>"
      clever: "<a href='/teachers/resources/clever-faq'>#{$.i18n.t('new_home_faq.clever_integration_faq')}</a>"
      contact: "<a class='contact-modal'>#{$.i18n.t('general.contact_us')}</a>"
      funding: "<a href='https://www.ozaria.com/funding' target='_blank'>#{$.i18n.t('nav.funding_resources_guide')}</a>"
      maintenanceStartTime: "#{context.maintenanceStartTime.calendar()} (#{context.maintenanceStartTime.fromNow()})"
      interpolation: { escapeValue: false }
    context

  getMeta: ->
    title: $.i18n.t 'new_home.title'
    meta: [
        { vmid: 'meta-description', name: 'description', content: $.i18n.t 'new_home.meta_description' }
    ],
    link: [
      { vmid: 'rel-canonical', rel: 'canonical', href: '/'  }
    ]

  onClickStudentButton: (e) ->
    @homePageEvent('Started Signup')
    @homePageEvent($(e.target).data('event-action'))
    @openModalView(new CreateAccountModal({startOnPath: 'student'}))

  onClickTeacherButton: (e) ->
    @homePageEvent($(e.target).data('event-action'))
    @openModalView(new CreateAccountModal({startOnPath: 'oz-vs-coco'}))

  onClickParentButton: (e) ->
    @homePageEvent($(e.target).data('event-action'))
    application.router.navigate '/parents', trigger: true

  onClickCreateAccountTeacherButton: (e) ->
    @homePageEvent('Started Signup')
    @openModalView(new CreateAccountModal({startOnPath: 'teacher'}))

  cleanupModals: ->
    if @ozariaEncouragementModal
      @ozariaEncouragementModal.$destroy()
      @ozariaEncouragementModalContainer.remove()
    if @getStartedSignupContainer
      @getStartedSignupContainer.$destroy()
      @getStartedSignupModal.remove()

  onClickTrackEvent: (e) ->
    @homePageEvent($(e.target).data('event-action'), {})

  # Provides a uniform interface for collecting information from the homepage.
  # Always provides the category Homepage and includes the user role.
  homePageEvent: (action, extraProperties={}) ->
    defaults =
      category: 'Homepage'
      user: me.get('role') || (me.isAnonymous() && "anonymous") || "homeuser"
    properties = _.merge(defaults, extraProperties)
    window.tracker?.trackEvent(action, properties)

  onClickAnchor: (e) ->
    return unless anchor = e?.currentTarget
    # Track an event with action of the English version of the link text
    translationKey = $(anchor).attr('data-i18n')
    translationKey ?= $(anchor).children('[data-i18n]').attr('data-i18n')
    if translationKey
      anchorText = $.i18n.t(translationKey, {lng: 'en-US'})
    else
      anchorText = anchor.text

    properties = {}
    if anchorText
      @homePageEvent("Link: #{anchorText}", properties)
    else
      properties.clicked = e?.currentTarget?.host or "unknown"
      @homePageEvent("Link:", properties)

  onClickGetStartedButton: (e) ->
    @homePageEvent($(e.target).data('event-action'))
    @getStartedSignupContainer?.remove()
    @getStartedSignupContainer = document.createElement('div')
    document.body.appendChild(@getStartedSignupContainer)
    @getStartedSignupModal = new GetStartedSignupModal({ el: @getStartedSignupContainer })

  onCarouselDirectMovev2: (e) ->
    selector = $(e.target).closest('.carousel-tab').data('selector')
    slideNum = $(e.target).closest('.carousel-tab').data('slide-num')
    @$(selector).carousel(slideNum)

  onCarouselDirectMove: (e) ->
    selector = $(e.target).closest('.carousel-dot').data('selector')
    slideNum = $(e.target).closest('.carousel-dot').data('slide-num')
    @$(selector).carousel(slideNum)

  onCarouselSlide: (e) =>
    $carousel = $(e.currentTarget).closest('.carousel')
    $carouselContainer = @$("##{$carousel.attr('id')}-carousel")
    slideNum = parseInt($(e.relatedTarget).data('slide'), 10)
    $carouselContainer.find(".carousel-tabs li:not(:nth-child(#{slideNum + 1}))").removeClass 'active'
    $carouselContainer.find(".carousel-tabs li:nth-child(#{slideNum + 1})").addClass 'active'
    $carouselContainer.find(".carousel-dot:not(:nth-child(#{slideNum + 1}))").removeClass 'active'
    $carouselContainer.find(".carousel-dot:nth-child(#{slideNum + 1})").addClass 'active'

  activateCarousels: =>
    return if @destroyed
    @$('.carousel').carousel().off().on 'slide.bs.carousel', @onCarouselSlide

  afterRender: ->
    if me.isAnonymous()
      if document.location.hash is '#create-account' or utils.getQueryVariable('registering') == true
        _.defer => @openModalView(new CreateAccountModal()) unless @destroyed
      if document.location.hash is '#create-account-individual'
        _.defer => @openModalView(new CreateAccountModal({startOnPath: 'individual'})) unless @destroyed
      if document.location.hash is '#create-account-home'
        _.defer => @openModalView(new CreateAccountModal({startOnPath: 'individual-basic'})) unless @destroyed
      if document.location.hash is '#create-account-student'
        _.defer => @openModalView(new CreateAccountModal({startOnPath: 'student'})) unless @destroyed
      if document.location.hash is '#create-account-teacher'
        _.defer => @openModalView(new CreateAccountModal({startOnPath: 'teacher'})) unless @destroyed

    if utils.getQueryVariable('payment-studentLicenses') in ['success', 'failed'] and not @renderedPaymentNoty
      paymentResult = utils.getQueryVariable('payment-studentLicenses')
      if paymentResult is 'success'
        title = $.i18n.t 'payments.studentLicense_successful'
        type = 'success'
        if utils.getQueryVariable 'tecmilenio'
          title = '¡Felicidades! El alumno recibirá más información de su profesor para acceder a la licencia de CodeCombat.'
        @trackPurchase("Student license purchase #{type}")
      else
        title = $.i18n.t 'payments.failed'
        type = 'error'
      noty({ text: title, type: type, timeout: 10000, killer: true })
      @renderedPaymentNoty = true
    else if utils.getQueryVariable('payment-homeSubscriptions') in ['success', 'failed'] and not @renderedPaymentNoty
      paymentResult = utils.getQueryVariable('payment-homeSubscriptions')
      if paymentResult is 'success'
        title = $.i18n.t 'payments.homeSubscriptions_successful'
        type = 'success'
        @trackPurchase("Home subscription purchase #{type}")
      else
        title = $.i18n.t 'payments.failed'
        type = 'error'
      noty({ text: title, type: type, timeout: 10000, killer: true })
      @renderedPaymentNoty = true
    _.delay(@activateCarousels, 1000)
    super()

  trackPurchase: (event) ->
    if !paymentUtils.hasTrackedPremiumAccess()
      @homePageEvent event, @getPaymentTrackingData()
      paymentUtils.setTrackedPremiumPurchase()

  getPaymentTrackingData: ->
    amount = utils.getQueryVariable('amount')
    duration = utils.getQueryVariable('duration')
    return paymentUtils.getTrackingData({ amount, duration })

  afterInsert: ->
    super()
    # scroll to the current hash, once everything in the browser is set up
    f = =>
      return if @destroyed
      link = $(document.location.hash)
      if link.length
        @scrollToLink(document.location.hash, 0)
    _.delay(f, 100)
    @loadCurator()

  shouldShowCurator: ->
    return false unless me.get('preferredLanguage', true).startsWith('en')  # Only English social media anyway
    return false if $(document).width() <= 700  # Curator is hidden in css on mobile anyway
    if (value = {true: true, false: false, show: true, hide: false}[utils.getQueryVariable 'curator'])?
      return value
    if (value = me.getExperimentValue('curator', null, 'show'))?
      return {show: true, hide: false}[value]
    if new Date(me.get('dateCreated')) < new Date('2022-03-17')
      # Don't include users created before experiment start date
      return true
    if features?.china
      # Don't include China users
      return true
    # Start a new experiment
    if me.get('testGroupNumber') % 2
      value = 'show'
    else
      value = 'hide'
    me.startExperiment('curator', value, 0.5)
    return {show: true, hide: false}[value]

  loadCurator: ->
    return if @curatorLoaded
    return unless @shouldShowCurator()
    @curatorLoaded = true
    script = document.createElement 'script'
    script.async = 1
    script.src = 'https://cdn.curator.io/published/4b3b9f97-3241-43b3-934e-f5a1eea5ae5e.js'
    firstScript = document.getElementsByTagName('script')[0]
    firstScript.parentNode.insertBefore(script, firstScript)
    @curatorInterval = setInterval @checkIfCuratorLoaded, 1000

  checkIfCuratorLoaded: =>
    return if @destroyed
    return unless @$('.crt-feed-spacer').length  # If we didn't find any of these, there's no content (not loaded or Curator error)
    @$('.testimonials-container, .curator-spacer').removeClass('hide')
    clearInterval @curatorInterval

  destroy: ->
    @cleanupModals()
    clearInterval @curatorInterval if @curatorInterval
    super()

  # 2021-06-08: currently causing issues with i18n interpolation, disabling for now
  # TODO: understand cause, performance impact
  #mergeWithPrerendered: (el) ->
  #  true
