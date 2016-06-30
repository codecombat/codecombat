RootView = require 'views/core/RootView'
template = require 'templates/new-home-view'
CocoCollection = require 'collections/CocoCollection'
TrialRequest = require 'models/TrialRequest'
TrialRequests = require 'collections/TrialRequests'
Course = require 'models/Course'
utils = require 'core/utils'
storage = require 'core/storage'
{logoutUser, me} = require('core/auth')

#  TODO: auto margin feature paragraphs

module.exports = class NewHomeView extends RootView
  id: 'new-home-view'
  className: 'style-flat'
  template: template

  events:
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
    'click .wiki-btn': 'onClickWikiButton'

  shortcuts:
    'right': 'onRightPressed'
    'left': 'onLeftPressed'
    'esc': 'onEscapePressed'

  initialize: (options) ->
    @courses = new CocoCollection [], {url: "/db/course", model: Course}
    @supermodel.loadCollection(@courses, 'courses')

    if me.isTeacher()
      @trialRequests = new TrialRequests()
      @trialRequests.fetchOwn()
      @supermodel.loadCollection(@trialRequests)

    isHourOfCodeWeek = false  # Temporary: default to /hoc flow during the main event week
    if isHourOfCodeWeek and (@isNewPlayer() or (me.justPlaysCourses() and me.isAnonymous()))
      # Go/return straight to playing single-player HoC course on Play click
      @playURL = '/hoc?go=true'
      @alternatePlayURL = '/play'
      @alternatePlayText = 'home.play_campaign_version'
    else if me.justPlaysCourses()
      # Save players who might be in a classroom from getting into the campaign
      @playURL = '/courses'
    else
      @playURL = '/play'

  onLoaded: ->
    @trialRequest = @trialRequests.first() if @trialRequests?.size()
    @isTeacherWithDemo = @trialRequest and @trialRequest.get('status') in ['approved', 'submitted']
    super()

  onClickLearnMoreLink: ->
    window.tracker?.trackEvent 'Homepage Click Learn More', category: 'Homepage', ['Mixpanel']
    @scrollToLink('#classroom-in-box-container')

  onClickPlayButton: (e) ->
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Homepage', ['Mixpanel']

  onClickRequestDemo: (e) ->
    @playSound 'menu-button-click'
    e.preventDefault()
    e.stopImmediatePropagation()
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Homepage', ['Mixpanel']
    if me.isTeacher()
      application.router.navigate '/teachers/update-account', trigger: true
    else
      application.router.navigate '/teachers/demo', trigger: true

  onClickSetupClass: (e) ->
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Homepage', ['Mixpanel']
    application.router.navigate("/teachers/classes", { trigger: true })

  onClickStudentButton: (e) ->
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Homepage', ['Mixpanel']

  onClickTeacherButton: (e) ->
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Homepage', ['Mixpanel']
    if me.isTeacher()
      application.router.navigate('/teachers', { trigger: true })
    else
      @scrollToLink('.request-demo-row', 600)

  onClickViewProfile: (e) ->
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Homepage', ['Mixpanel']
    application.router.navigate("/user/#{me.getSlugOrID()}", { trigger: true })

  onClickWikiButton: (e) ->
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Homepage', ['Mixpanel']
    window.location.href = 'https://sites.google.com/a/codecombat.com/teacher-guides/course-guides'

  afterRender: ->
    @onChangeSchoolLevelDropdown()
    @$('#screenshot-lightbox').modal()
    @$('#screenshot-carousel').carousel({
      interval: 0
      keyboard: false
    })
    $(window).on 'resize', @fitToPage
    @fitToPage()
    setTimeout(@fitToPage, 0)
    if me.isAnonymous()
      CreateAccountModal = require 'views/core/CreateAccountModal/CreateAccountModal'
      if document.location.hash is '#create-account'
        @openModalView(new CreateAccountModal())
      if document.location.hash is '#create-account-individual'
        @openModalView(new CreateAccountModal({startOnPath: 'individual'}))
      if document.location.hash is '#create-account-student'
        @openModalView(new CreateAccountModal({startOnPath: 'student'}))
    super()

  destroy: ->
    $(window).off 'resize', @fitToPage
    super()

  logoutAccount: ->
    Backbone.Mediator.publish("auth:logging-out", {})
    logoutUser()

  onChangeSchoolLevelDropdown: (e) ->
    levels =
      elementary: {'introduction-to-computer-science': '2-4', 'computer-science-6': '24-30', 'computer-science-7': '30-40', 'computer-science-8': '30-40', default: '16-25', total: '150-215 hours (about two and a half years)'}
      middle: {'introduction-to-computer-science': '1-3', 'computer-science-6': '12-14', 'computer-science-7': '14-16', 'computer-science-8': '14-16', default: '8-12', total: '75-100 hours (about one and a half years)'}
      high: {'introduction-to-computer-science': '1', 'computer-science-6': '10-12', 'computer-science-7': '12-16', 'computer-science-8': '12-16', default: '8-10', total: '65-85 hours (about one year)'}
    level = if e then $(e.target).val() else 'middle'
    @$el.find('#courses-row .course-details').each ->
      slug = $(@).data('course-slug')
      duration = levels[level][slug] or levels[level].default
      $(@).find('.course-duration .course-hours').text duration
      $(@).find('.course-duration .unit').text($.i18n.t(if duration is '1' then 'units.hour' else 'units.hours'))
    @$el.find('#semester-duration').text levels[level].total

  isNewPlayer: ->
    not me.get('stats')?.gamesCompleted and not me.get('heroConfig')

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
