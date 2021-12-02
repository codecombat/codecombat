require('app/styles/home-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/home-view'
CocoCollection = require 'collections/CocoCollection'
utils = require 'core/utils'
storage = require 'core/storage'
{logoutUser, me} = require('core/auth')
CreateAccountModal = require 'views/core/CreateAccountModal/CreateAccountModal'
EducatorSignupOzariaEncouragementModal = require('app/views/teachers/EducatorSignupOzariaEncouragementModal').default
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
    context.i18nData =
      slides: "<a href='https://docs.google.com/presentation/d/1KgFOg2tqbKEH8qNwIBdmK2QbHvTsxnW_Xo7LvjPsxwE/edit?usp=sharing' target='_blank'>#{$.i18n.t('new_home.lesson_slides')}</a>"
      clever: "<a href='/teachers/resources/clever-faq'>#{$.i18n.t('new_home_faq.clever_integration_faq')}</a>"
      contact: "<a class='contact-modal'>#{$.i18n.t('general.contact_us')}</a>"
      funding: "<a href='https://www.ozaria.com/funding' target='_blank'>#{$.i18n.t('nav.funding_resources_guide')}</a>"
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
    @openEducatorSignupOzariaEncouragementModal(() =>
      @homePageEvent('Started Signup')
      @openModalView(new CreateAccountModal({startOnPath: 'teacher'}))
    )

  onClickParentButton: (e) ->
    @homePageEvent($(e.target).data('event-action'))
    application.router.navigate '/parents', trigger: true

  onClickCreateAccountTeacherButton: (e) ->
    @homePageEvent('Started Signup')
    @openModalView(new CreateAccountModal({startOnPath: 'teacher'}))

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
  homePageEvent: (action, extraproperties={}, includeIntegrations=[]) ->
    defaults =
      category: 'Homepage'
      user: me.get('role') || (me.isAnonymous() && "anonymous") || "homeuser"
    properties = _.merge(defaults, extraproperties)
    window.tracker?.trackEvent(action, properties, includeIntegrations)

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
      @homePageEvent("Link: #{anchorText}", properties, ['Google Analytics'])
    else
      properties.clicked = e?.currentTarget?.host or "unknown"
      @homePageEvent("Link:", properties, ['Google Analytics'])

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
      if document.location.hash is '#create-account-student'
        _.defer => @openModalView(new CreateAccountModal({startOnPath: 'student'})) unless @destroyed
      if document.location.hash is '#create-account-teacher'
        _.defer => @openModalView(new CreateAccountModal({startOnPath: 'teacher'})) unless @destroyed

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
    else if utils.getQueryVariable('payment-homeSubscriptions') in ['success', 'failed'] and not @renderedPaymentNoty
      paymentResult = utils.getQueryVariable('payment-homeSubscriptions')
      if paymentResult is 'success'
        title = $.i18n.t 'payments.homeSubscriptions_successful'
        type = 'success'
      else
        title = $.i18n.t 'payments.failed'
        type = 'error'
      noty({ text: title, type: type, timeout: 10000, killer: true })
      @renderedPaymentNoty = true
    _.delay(@activateCarousels, 1000)
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

  destroy: ->
    @cleanupModals()
    super()

  # 2021-06-08: currently causing issues with i18n interpolation, disabling for now
  # TODO: understand cause, performance impact
  #mergeWithPrerendered: (el) ->
  #  true
