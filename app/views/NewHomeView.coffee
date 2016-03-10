RootView = require 'views/core/RootView'
template = require 'templates/new-home-view'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
utils = require 'core/utils'

#  TODO: auto margin feature paragraphs

module.exports = class NewHomeView extends RootView
  id: 'new-home-view'
  className: 'style-flat'
  template: template

  events:
    'click #play-btn': 'onClickPlayButton'
    'change #school-level-dropdown': 'onChangeSchoolLevelDropdown'
    'click #teacher-btn': 'onClickTeacherButton'
    'click #learn-more-link': 'onClickLearnMoreLink'
    'click .screen-thumbnail': 'onClickScreenThumbnail'
    'click #carousel-left': 'onLeftPressed'
    'click #carousel-right': 'onRightPressed'

  shortcuts:
    'right': 'onRightPressed'
    'left': 'onLeftPressed'
    'esc': 'onEscapePressed'

  initialize: (options) ->
    @jumbotron = options.jumbotron or utils.getQueryVariable('jumbotron') or 'student'
    @courses = new CocoCollection [], {url: "/db/course", model: Course}
    @supermodel.loadCollection(@courses, 'courses')

    window.tracker?.trackEvent 'Homepage Loaded', category: 'Homepage'
    if @getQueryVariable 'hour_of_code'
      application.router.navigate "/hoc", trigger: true

    isHourOfCodeWeek = false  # Temporary: default to /hoc flow during the main event week
    if isHourOfCodeWeek and (@isNewPlayer() or (@justPlaysCourses() and me.isAnonymous()))
      # Go/return straight to playing single-player HoC course on Play click
      @playURL = '/hoc?go=true'
      @alternatePlayURL = '/play'
      @alternatePlayText = 'home.play_campaign_version'
    else if @justPlaysCourses()
      # Save players who might be in a classroom from getting into the campaign
      @playURL = '/courses'
      @alternatePlayURL = '/play'
      @alternatePlayText = 'home.play_campaign_version'
    else
      @playURL = '/play'

  onClickPlayButton: (e) ->
    @playSound 'menu-button-click'
    return if @playURL isnt '/play'
    window.tracker?.trackEvent 'Click Play', category: 'Homepage'

  afterRender: ->
    @onChangeSchoolLevelDropdown()
    @$('#screenshot-lightbox').modal()
    @$('#screenshot-carousel').carousel({
      interval: 0
      keyboard: false
    })
    super()

  onChangeSchoolLevelDropdown: (e) ->
    levels =
      elementary: {'introduction-to-computer-science': '2-4', 'computer-science-5': '15-20', default: '10-15', total: '50-70 hours (about one year)'}
      middle: {'introduction-to-computer-science': '1-3', 'computer-science-5': '7-10', default: '5-8', total: '25-35 hours (about one semester)'}
      high: {'introduction-to-computer-science': '1', 'computer-science-5': '6-9', default: '5-6', total: '22-28 hours (about one semester)'}
    level = if e then $(e.target).val() else 'middle'
    @$el.find('#courses-row .course-details').each ->
      slug = $(@).data('course-slug')
      duration = levels[level][slug] or levels[level].default
      $(@).find('.course-duration .course-hours').text duration
      $(@).find('.course-duration .unit').text($.i18n.t(if duration is '1' then 'units.hour' else 'units.hours'))
    @$el.find('#semester-duration').text levels[level].total

  justPlaysCourses: ->
    # This heuristic could be better, but currently we don't add to me.get('courseInstances') for single-player anonymous intro courses, so they have to beat a level without choosing a hero.
    return me.get('stats')?.gamesCompleted and not me.get('heroConfig')

  isNewPlayer: ->
    not me.get('stats')?.gamesCompleted and not me.get('heroConfig')

  onClickLearnMoreLink: ->
    @scrollToLink('#classroom-in-box-container')

  onClickTeacherButton: ->
    @scrollToLink('.request-demo-row', 600)

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
