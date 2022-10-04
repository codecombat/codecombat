require('app/styles/home-view.scss')
RootView = require 'views/core/RootView'
template = require 'templates/home-view'
CocoCollection = require 'collections/CocoCollection'
CreateAccountModal = require 'views/core/CreateAccountModal/CreateAccountModal'

utils = require 'core/utils'
storage = require 'core/storage'
{logoutUser, me} = require('core/auth')
fetchJson = require 'core/api/fetch-json'
DOMPurify = require 'dompurify'

module.exports = class HomeView extends RootView
  id: 'home-view'
  template: template

  events:
    'click .student-btn': 'onClickStudentButton'
    'click .teacher-btn': 'onClickTeacherButton'
    'click .request-quote': 'onClickRequestQuote'
    'click .logout-btn': 'logoutAccount'
    'click .setup-class-btn': 'onClickSetupClass'
    'click .try-chapter-1': 'onClickGenericTryChapter1'
    'click .contact-us': 'onClickContactModal'
    'click a': 'onClickAnchor'

  initialize: (options) ->
    super(options)
    @getBanner()

  getRenderData: (context={}) ->
    context = super context
    context.maintenanceStartTime = moment('2022-05-07T16:00:00-07:00')
    context.i18nData =
      pd: "<a href='/professional-development'>#{$.i18n.t('nav.professional_development')}</a>"
      maintenanceStartTime: "#{context.maintenanceStartTime.calendar()} (#{context.maintenanceStartTime.fromNow()})"
      interpolation: { escapeValue: false }
    context

  getMeta: ->
    title: $.i18n.t 'new_home.title_ozar'
    meta: [
        { vmid: 'meta-description', name: 'description', content: $.i18n.t 'new_home.meta_description_ozar' },
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
    @openModalView(new CreateAccountModal({startOnPath: 'student'}))

  onClickTeacherButton: (e) ->
    @homePageEvent('Started Signup')
    @openModalView(new CreateAccountModal({startOnPath: 'teacher'}))

  # Provides a uniform interface for collecting information from the homepage.
  # Always provides the category Homepage and includes the user role.
  homePageEvent: (action, extraproperties={}) ->
    action = action or 'unknown'
    defaults =
      category: 'Home'
      user: me.get('role') || (me.isAnonymous() && "anonymous") || "homeuser"
    properties = _.merge(defaults, extraproperties)
    window.tracker?.trackEvent(action, properties)

  onClickAnchor: (e) ->
    return unless anchor = e?.currentTarget
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

  afterRender: ->
    if me.isAnonymous()
      if document.location.hash is '#create-account'
        @openModalView(new CreateAccountModal())
      if document.location.hash is '#create-account-individual'
        @openModalView(new CreateAccountModal({startOnPath: 'individual'}))
      if document.location.hash is '#create-account-student'
        @openModalView(new CreateAccountModal({startOnPath: 'student'}))
      if document.location.hash is '#create-account-teacher'
        @openModalView(new CreateAccountModal({startOnPath: 'teacher'}))

    window.addEventListener 'load', ->
      $('#core-curriculum-carousel').data('bs.carousel').$element.on 'slid.bs.carousel', (event) ->
        nextActiveSlide = $(event.relatedTarget).index()
        $buttons = $('.control-buttons > button')
        $buttons.removeClass 'active'
        $('[data-slide-to=\'' + nextActiveSlide + '\']').addClass('active')
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

  onCarouselLeft: ->
    $("#core-curriculum-carousel").carousel('prev')
  onCarouselRight: ->
    $("#core-curriculum-carousel").carousel('next')

  onCarouselDirectMove: (frameNum) ->
    $("#core-curriculum-carousel").carousel(frameNum)

  logoutAccount: ->
    Backbone.Mediator.publish("auth:logging-out", {})
    logoutUser()
