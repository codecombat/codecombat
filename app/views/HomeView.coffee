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
  className: 'style-flat'
  template: template

  events:
    'click .open-video-btn': 'onClickOpenVideoButton'
    'click .play-btn': 'onClickPlayButton'
    'change #school-level-dropdown': 'onChangeSchoolLevelDropdown'
    'click .student-btn': 'onClickStudentButton'
    'click .teacher-btn': 'onClickTeacherButton'
    'click #learn-more-link': 'onClickLearnMoreLink'
    'click .screen-thumbnail': 'onClickScreenThumbnail'
    'click #carousel-left': 'onLeftPressed'
    'click #carousel-right': 'onRightPressed'
    'click .request-demo': 'onClickRequestDemo'
    'click .logout-btn': 'logoutAccount'
    'click .profile-btn': 'onClickViewProfile'
    'click .setup-class-btn': 'onClickSetupClass'
    'click .my-classes-btn': 'onClickMyClassesButton'
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

    isHourOfCodeWeek = false  # Temporary: default to hourOfCode flow during the main event week
    @playURL = if me.isStudent()
      '/students'
    else if isHourOfCodeWeek
      '/play?hour_of_code=true'
    else
      '/play'

  onLoaded: ->
    @trialRequest = @trialRequests.first() if @trialRequests?.size()
    @isTeacherWithDemo = @trialRequest and @trialRequest.get('status') in ['approved', 'submitted']
    super()

  onClickOpenVideoButton: (event) ->
    unless @$('#screenshot-lightbox').data('bs.modal')?.isShown
      event.preventDefault()
      # Modal opening happens automatically from bootstrap
      @$('#screenshot-carousel').carousel($(event.currentTarget).data("index"))
    @vimeoPlayer.play()

  onCloseLightbox: ->
    @vimeoPlayer.pause()

  onClickLearnMoreLink: ->
    window.tracker?.trackEvent 'Homepage Click Learn More', category: 'Homepage', []
    @scrollToLink('#classroom-in-box-container')

  onClickPlayButton: (e) ->
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Homepage', []

  onClickRequestDemo: (e) ->
    @playSound 'menu-button-click'
    e.preventDefault()
    e.stopImmediatePropagation()
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Homepage', []
    if me.isTeacher()
      application.router.navigate '/teachers/update-account', trigger: true
    else
      application.router.navigate '/teachers/demo', trigger: true

  onClickSetupClass: (e) ->
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Homepage', []
    application.router.navigate("/teachers/classes", { trigger: true })

  onClickStudentButton: (e) ->
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Homepage', []
    @openModalView(new CreateAccountModal({startOnPath: 'student'}))

  onClickTeacherButton: (e) ->
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Homepage', []
    @openModalView(new CreateAccountModal({startOnPath: 'teacher'}))

  onClickViewProfile: (e) ->
    e.preventDefault()
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Homepage', []

  onClickMyClassesButton: (e) ->
    e.preventDefault()
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Homepage', []

  onClickResourceButton: (e) ->
    e.preventDefault()
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
      console.log e
    , 'vimeo')
    @onChangeSchoolLevelDropdown()
    @$('#screenshot-lightbox')
      .modal()
      .on 'hide.bs.modal', (e)=>
        @vimeoPlayer.pause()
      .on 'shown.bs.modal', (e)=>
        if @$('.video-carousel-item').hasClass('active')
          @vimeoPlayer.play()
    @$('#screenshot-carousel')
      .carousel({
        interval: 0
        keyboard: false
      })
      .on 'slide.bs.carousel', (e) =>
        if not $(e.relatedTarget).hasClass('.video-carousel-item')
          @vimeoPlayer.pause()
    $(window).on 'resize', @fitToPage
    @fitToPage()
    setTimeout(@fitToPage, 0)
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

  destroy: ->
    $(window).off 'resize', @fitToPage
    super()

  logoutAccount: ->
    Backbone.Mediator.publish("auth:logging-out", {})
    logoutUser()

  onChangeSchoolLevelDropdown: (e) ->
    levels =
      elementary:
        'introduction-to-computer-science': '2-4'
        'game-development-1': '2-3'
        'web-development-1': '2-3'
        'game-development-2': '2-3'
        'web-development-2': '2-3'
        'computer-science-6': '24-30'
        'computer-science-7': '30-40'
        'computer-science-8': '30-40'
        default: '16-25'
        total: '150-215 hours (about two and a half years)'
      middle:
        'introduction-to-computer-science': '1-3'
        'game-development-1': '1-3'
        'web-development-1': '1-3'
        'game-development-2': '1-3'
        'web-development-2': '1-3'
        'computer-science-6': '12-14'
        'computer-science-7': '14-16'
        'computer-science-8': '14-16'
        default: '8-12'
        total: '75-100 hours (about one and a half years)'
      high:
        'introduction-to-computer-science': '1'
        'game-development-1': '1-2'
        'web-development-1': '1-2'
        'game-development-2': '1-2'
        'web-development-2': '1-2'
        'computer-science-6': '10-12'
        'computer-science-7': '12-16'
        'computer-science-8': '12-16'
        default: '8-10'
        total: '65-85 hours (about one year)'
    level = if e then $(e.target).val() else 'middle'
    @$el.find('#courses-row .course-details').each ->
      slug = $(@).data('course-slug')
      duration = levels[level][slug] or levels[level].default
      $(@).find('.course-duration .course-hours').text duration
      $(@).find('.course-duration .unit').text($.i18n.t(if duration is '1' then 'units.hour' else 'units.hours'))
    @$el.find('#semester-duration').text levels[level].total

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

  fitToPage: =>
    windowHeight = $(window).height()
    linkBox = @$("#learn-more-link").parent()
    linkOffset = linkBox.offset()
    adjustment = windowHeight - (linkOffset.top + linkBox.height())
    target = @$('.top-spacer').first()
    newOffset = parseInt(target.css('height') || 0) + adjustment
    newOffset = Math.min(Math.max(0, newOffset), 170)
    target.css(height: "#{newOffset}px")

  mergeWithPrerendered: (el) ->
    true
