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
fetchJson = require 'core/api/fetch-json'
DOMPurify = require 'dompurify'

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
    @getBanner()

  getRenderData: (context={}) ->
    context = super context
    context.maintenanceStartTime = moment('2022-05-07T16:00:00-07:00')
    context.i18nData =
      slides: "<a href='https://docs.google.com/presentation/d/1KgFOg2tqbKEH8qNwIBdmK2QbHvTsxnW_Xo7LvjPsxwE/edit?usp=sharing' target='_blank'>#{$.i18n.t('new_home.lesson_slides')}</a>"
      clever: "<a href='/teachers/resources/clever-faq'>#{$.i18n.t('new_home_faq.clever_integration_faq')}</a>"
      contact: if me.isTeacher() then "<a class='contact-modal'>#{$.i18n.t('general.contact_us')}</a>" else "<a href=\"mailto:support@codecombat.com\">#{$.i18n.t('general.contact_us')}</a>"
      funding: "<a href='https://www.ozaria.com/funding' target='_blank'>#{$.i18n.t('nav.funding_resources_guide')}</a>"
      maintenanceStartTime: "#{context.maintenanceStartTime.calendar()} (#{context.maintenanceStartTime.fromNow()})"
      interpolation: { escapeValue: false }
      topBannerHereLink: "<a href='/teachers/hour-of-code' target='_blank'>#{$.i18n.t('new_home.top_banner_blurb_hoc_2022_12_01_here')}</a>"
    context

  getMeta: ->
    title: $.i18n.t 'new_home.title_coco'
    meta: [
        { vmid: 'meta-description', name: 'description', content: $.i18n.t 'new_home.meta_description_coco' }
    ],
    link: [
      { vmid: 'rel-canonical', rel: 'canonical', href: '/'  }
    ]

  getBanner: ->
    fetchJson('/db/banner').then((data) =>
      @banner = data
      content = utils.i18n data, 'content'
      @banner.display = DOMPurify.sanitize marked(content ? '')
      @renderSelectors('#top-banner')
    )

  onClickStudentButton: (e) ->
    @homePageEvent('Started Signup')
    @homePageEvent($(e.target).data('event-action'))
    @openModalView(new CreateAccountModal({startOnPath: 'student'}))

  onClickTeacherButton: (e) ->
    @homePageEvent($(e.target).data('event-action'))
    @openModalView(new CreateAccountModal({startOnPath: 'oz-vs-coco'}))

  onClickParentButton: (e) ->
    @homePageEvent($(e.target).data('event-action'))
    application.router.navigate '/parents/signup', trigger: true

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
      if utils.getQueryVariable('create-account') is 'teacher'
        _.defer => @openModalView(new CreateAccountModal({startOnPath: 'teacher'})) unless @destroyed
      if document.location.hash is '#login'
        AuthModal = require 'app/views/core/AuthModal'
        url = new URLSearchParams window.location.search
        _.defer => @openModalView(new AuthModal({initialValues:{email: url.get 'email'}})) unless @destroyed

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
      try
        link = $(document.location.hash)
        if link.length
          @scrollToLink(document.location.hash, 0)
      catch e
        console.warn e  # Possibly a hash that would not match a valid element
    _.delay(f, 100)

  destroy: ->
    @cleanupModals()
    super()

  # 2021-06-08: currently causing issues with i18n interpolation, disabling for now
  # TODO: understand cause, performance impact
  #mergeWithPrerendered: (el) ->
  #  true
