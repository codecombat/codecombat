ModalView = require 'views/core/ModalView'
template = require 'templates/play/level/modal/course-victory-modal'
Level = require 'models/Level'
Course = require 'models/Course'
LevelSessions = require 'collections/LevelSessions'
ProgressView = require './ProgressView'
Classroom = require 'models/Classroom'
utils = require 'core/utils'

module.exports = class CourseVictoryModal extends ModalView
  id: 'course-victory-modal'
  template: template
  closesOnClickOutside: false

  initialize: (options) ->
    @courseID = options.courseID
    @courseInstanceID = options.courseInstanceID or @getQueryVariable 'course-instance' or @getQueryVariable 'league'
    @views = []

    @session = options.session
    @level = options.level

    if @courseInstanceID
      @classroom = new Classroom()
      @supermodel.trackRequest(@classroom.fetchForCourseInstance(@courseInstanceID))

    @playSound 'victory'
    @nextLevel = new Level()
    @nextLevelRequest = @supermodel.trackRequest(@nextLevel.fetchNextForCourse({
      levelOriginalID: @level.get('original')
      @courseInstanceID
      @courseID
      sessionID: @session.id
    }))

    @course = options.course
    if @courseID and not @course
      @course = new Course().setURL "/db/course/#{@courseID}"
      @course = @supermodel.loadModel(@course).model

    if @courseInstanceID
      @levelSessions = new LevelSessions()
      @levelSessions.fetchForCourseInstance(@courseInstanceID)
      @levelSessions = @supermodel.loadCollection(@levelSessions, 'sessions', {
        data: { project: 'state.complete level.original playtime changed' }
      }).model

      if not @course
        @course = new Course()
        @supermodel.trackRequest @course.fetchForCourseInstance(@courseInstanceID)

    window.tracker?.trackEvent 'Play Level Victory Modal Loaded', category: 'Students', levelSlug: @level.get('slug'), ['Mixpanel']

  onResourceLoadFailed: (e) ->
    if e.resource.jqxhr is @nextLevelRequest
      return
    super(arguments...)

  onLoaded: ->
    super()
    @courseID ?= @course.id
    @views = []

    @levelSessions?.remove(@session)
    @levelSessions?.add(@session)
    progressView = new ProgressView({
      level: @level
      nextLevel: @nextLevel
      course: @course
      classroom: @classroom
      levelSessions: @levelSessions
      session: @session
    })

    progressView.once 'done', @onDone, @
    progressView.once 'next-level', @onNextLevel, @
    progressView.once 'ladder', @onLadder, @
    for view in @views
      view.on 'continue', @onViewContinue, @
    @views.push(progressView)

    @showView(_.first(@views))

  afterRender: ->
    super()
    @showView(@currentView)

  showView: (view) ->
    return unless view
    view.setElement(@$('.modal-content'))
    view.$el.attr('id', view.id)
    view.$el.addClass(view.className)
    view.render()
    @currentView = view

  onViewContinue: ->
    index = _.indexOf(@views, @currentView)
    @showView(@views[index+1])

  onNextLevel: ->
    window.tracker?.trackEvent 'Play Level Victory Modal Next Level', category: 'Students', levelSlug: @level.get('slug'), nextLevelSlug: @nextLevel.get('slug'), ['Mixpanel']
    if me.isSessionless()
      link = "/play/level/#{@nextLevel.get('slug')}?course=#{@courseID}&codeLanguage=#{utils.getQueryVariable('codeLanguage', 'python')}"
    else
      link = "/play/level/#{@nextLevel.get('slug')}?course=#{@courseID}&course-instance=#{@courseInstanceID}"
    application.router.navigate(link, {trigger: true})

  onDone: ->
    window.tracker?.trackEvent 'Play Level Victory Modal Done', category: 'Students', levelSlug: @level.get('slug'), ['Mixpanel']
    if me.isSessionless()
      link = '/teachers/courses'
    else
      link = '/courses'
    application.router.navigate(link, {trigger: true})

  onLadder: ->
    # Preserve the supermodel as we navigate back to the ladder.
    viewArgs = [{supermodel: if @options.hasReceivedMemoryWarning then null else @supermodel}, @level.get('slug')]
    ladderURL = "/play/ladder/#{@level.get('slug') || @level.id}"
    if leagueID = (@courseInstanceID or @getQueryVariable 'league')
      leagueType = if @level.get('type') is 'course-ladder' then 'course' else 'clan'
      viewArgs.push leagueType
      viewArgs.push leagueID
      ladderURL += "/#{leagueType}/#{leagueID}"
    ladderURL += '#my-matches'
    Backbone.Mediator.publish 'router:navigate', route: ladderURL, viewClass: 'views/ladder/LadderView', viewArgs: viewArgs
