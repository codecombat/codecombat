require('app/styles/home-view.sass')
require('app/styles/home-view.scss')
RootView = require 'views/core/RootView'
cocoTemplate = require 'templates/coco-home-view'
ozarTemplate = require 'templates/ozar-home-view'
CocoCollection = require 'collections/CocoCollection'
utils = require 'core/utils'
storage = require 'core/storage'
{logoutUser, me} = require('core/auth')
CreateAccountModal = require 'views/core/CreateAccountModal/CreateAccountModal'
GetStartedSignupModal  = require('app/views/teachers/GetStartedSignupModal').default
paymentUtils = require 'app/lib/paymentUtils'
fetchJson = require 'core/api/fetch-json'
DOMPurify = require 'dompurify'
PRODUCT_SUFFIX = if utils.isCodeCombat then 'coco' else 'ozar'
module.exports = class HomeView extends RootView
  id: 'home-view'
  template: if utils.isCodeCombat then cocoTemplate else ozarTemplate

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
    'click .request-quote': 'onClickRequestQuote'
    'click .logout-btn': 'logoutAccount'
    'click .setup-class-btn': 'onClickSetupClass'
    'click .try-chapter-1': 'onClickGenericTryChapter1'
    'click .contact-us': 'onClickContactModal'

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
      codecombatHome: "<a href='/premium' target='_blank'>#{$.i18n.t('new_home.codecombat_home')}</a>"
      pd: "<a href='/professional-development'>#{$.i18n.t('nav.professional_development')}</a>"
      maintenanceStartTime: "#{context.maintenanceStartTime.calendar()} (#{context.maintenanceStartTime.fromNow()})"
      interpolation: { escapeValue: false }
      topBannerHereLink: "<a href='https://codecombat.com/teachers/hour-of-code' target='_blank'>#{$.i18n.t('new_home.top_banner_blurb_hoc_2022_12_01_here')}</a>"
    context

  getMeta: ->
    title: $.i18n.t('new_home.title_' + PRODUCT_SUFFIX)
    meta: [
        { vmid: 'meta-description', name: 'description', content: $.i18n.t 'new_home.meta_description_' + PRODUCT_SUFFIX }
        { vmid: 'viewport', name: 'viewport', content: 'width=device-width, initial-scale=1' }
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

  onClickGenericTryChapter1: (e) ->
    @homePageEvent($(e.target).data('event-action'))
    window.open('/hoc', '_blank')

  onClickStudentButton: (e) ->
    @homePageEvent('Started Signup')
    @homePageEvent($(e.target).data('event-action'))
    @openModalView(new CreateAccountModal({startOnPath: 'student'}))

  onClickTeacherButton: (e) ->
    if utils.isCodeCombat
      @homePageEvent($(e.target).data('event-action'))
      @openModalView(new CreateAccountModal({startOnPath: 'oz-vs-coco'}))
    else
      @homePageEvent('Started Signup')
      @openModalView(new CreateAccountModal({startOnPath: 'teacher'}))

  onClickParentButton: (e) ->
    @homePageEvent($(e.target).data('event-action'))
    application.router.navigate '/parents/signup', trigger: true

  onClickCreateAccountTeacherButton: (e) ->
    @homePageEvent('Started Signup')
    @openModalView(new CreateAccountModal({startOnPath: 'teacher'}))

  cleanupModals: ->
    if @getStartedSignupContainer
      @getStartedSignupContainer.$destroy()
      @getStartedSignupModal.remove()

  onClickTrackEvent: (e) ->
    @homePageEvent($(e.target).data('event-action'), {})

  # Provides a uniform interface for collecting information from the homepage.
  # Always provides the category Homepage and includes the user role.
  homePageEvent: (action, extraProperties={}) ->
    action = action or 'unknown'
    defaults =
      category: if utils.isCodeCombat then 'Homepage' else 'Home'
      user: me.get('role') || (me.isAnonymous() && "anonymous") || "homeuser"
    properties = _.merge(defaults, extraProperties)
    window.tracker?.trackEvent(action, properties)

  onClickAnchor: (e) ->
    return unless anchor = e?.currentTarget
    if utils.isCodeCombat
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
    else
      anchorEventAction = $(anchor).data('event-action')
      unless anchorEventAction
        # Track an event with action of the English version of the link text
        translationKey = $(anchor).data('i18n')
        translationKey ?= $(anchor).children('[data-i18n]').data('i18n')
        anchorEventAction = if translationKey then $.i18n.t(translationKey, {lng: 'en-US'}) else anchor.text
        anchorEventAction = "Click: #{anchorEventAction or 'unknown'}"

      if anchorEventAction
        @homePageEvent(anchorEventAction)
      else
        _.extend(properties || {}, {
          clicked: e?.currentTarget?.host or "unknown"
        })
        @homePageEvent('Click: unknown')

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
    if utils.isCodeCombat
      selector = $(e.target).closest('.carousel-dot').data('selector')
      slideNum = $(e.target).closest('.carousel-dot').data('slide-num')
      @$(selector).carousel(slideNum)
    else
      frameNum = e
      $("#core-curriculum-carousel").carousel(frameNum)

  onCarouselLeft: ->
    $("#core-curriculum-carousel").carousel('prev')
  onCarouselRight: ->
    $("#core-curriculum-carousel").carousel('next')


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

    if utils.isCodeCombat
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
    else
      window.addEventListener 'load', ->
        $('#core-curriculum-carousel').data('bs.carousel')?.$element.on 'slid.bs.carousel', (event) ->
          nextActiveSlide = $(event.relatedTarget).index()
          $buttons = $('.control-buttons > button')
          $buttons.removeClass 'active'
          $('[data-slide-to=\'' + nextActiveSlide + '\']').addClass('active')
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

  logoutAccount: ->
    Backbone.Mediator.publish("auth:logging-out", {})
    logoutUser()

  destroy: ->
    @cleanupModals()
    super()

  # 2021-06-08: currently causing issues with i18n interpolation, disabling for now
  # TODO: understand cause, performance impact
  #mergeWithPrerendered: (el) ->
  #  true
