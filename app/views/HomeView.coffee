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
    'click a': 'onClickAnchor'
    'click .get-started-btn': 'onClickGetStarted'

  initialize: (options) ->
    super(options)

    # NOTE: The [html] way does not work in this template for some reason?
    # When fixed, use this for en.coffee:
    # new_adventure_game_blurb: "Ozaria is our brand new adventure game and your turnkey solution for teaching Computer science. Our student-facing __slides__ and teacher-facing notes make planning and delivering lessons easier and faster."
    #
    # @i18nData = {
    #   slides: "<a href='https://docs.google.com/presentation/d/1KgFOg2tqbKEH8qNwIBdmK2QbHvTsxnW_Xo7LvjPsxwE/edit?usp=sharing'>#{$.i18n.t('new_home.lesson_slides')}</a>"
    # }

    @renderedPaymentNoty = false

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

    if $(e.target)?.hasClass('track-ab-result')
      properties = {trackABResult: true}

    if anchorText
      @homePageEvent("Link: #{anchorText}", properties || {}, ['Google Analytics'])
    else
      _.extend(properties || {}, {
        clicked: e?.currentTarget?.host or "unknown"
      })
      @homePageEvent("Link:", properties, ['Google Analytics'])

  onClickGetStarted: (e) ->
    # TODO: Add event tracking here
    # @homePageEvent($(e.target).data('event-action'))
    @getStartedSignupContainer?.remove()
    @getStartedSignupContainer = document.createElement('div')
    document.body.appendChild(@getStartedSignupContainer)
    @getStartedSignupModal = new GetStartedSignupModal({ el: @getStartedSignupContainer })

  onCarouselDirectMove: (selector, slideNum) ->
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
    @$('.carousel').carousel().on 'slide.bs.carousel', @onCarouselSlide

  afterRender: ->
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
    _.delay(@activateCarousels, 1000)

  destroy: ->
    @cleanupModals()
    super()

  mergeWithPrerendered: (el) ->
    true
