require('app/styles/play/level/modal/course-victory-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/play/level/modal/course-victory-modal'
Level = require 'models/Level'
Course = require 'models/Course'
LevelSessions = require 'collections/LevelSessions'
ProgressView = require './ProgressView'
Classroom = require 'models/Classroom'
utils = require 'core/utils'
api = require('core/api')
urls = require 'core/urls'

module.exports = class CourseVictoryModal extends ModalView
  id: 'course-victory-modal'
  template: template
  closesOnClickOutside: false

  initialize: (options) ->
    @courseID = options.courseID
    @courseInstanceID = options.courseInstanceID or utils.getQueryVariable('course-instance') or utils.getQueryVariable('league')
    @views = []

    @session = options.session
    @level = options.level

    if @courseInstanceID
      @classroom = new Classroom()
      @supermodel.trackRequest(@classroom.fetchForCourseInstance(@courseInstanceID))

    @playSound 'victory'
    @nextLevel = new Level()
    @nextAssessment = new Level()
    nextLevelPromise = api.levels.fetchNextForCourse({
      levelOriginalID: @level.get('original')
      @courseInstanceID
      @courseID
      sessionID: @session.id
    }).then ({ level, assessment }) =>
      @nextLevel.set(level)
      @nextAssessment.set(assessment)
    @supermodel.trackPromise(nextLevelPromise)

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

    window.tracker?.trackEvent 'Play Level Victory Modal Loaded', category: 'Students', levelSlug: @level.get('slug'), []
    if @level.isProject()
      @galleryURL = urls.projectGallery({ @courseInstanceID })

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
      nextAssessment: @nextAssessment
      course: @course
      classroom: @classroom
      levelSessions: @levelSessions
      session: @session
      courseInstanceID: @courseInstanceID
    })

    progressView.once 'done', @onDone, @
    progressView.once 'next-level', @onNextLevel, @
    progressView.once 'start-challenge', @onStartChallenge, @
    progressView.once 'to-map', @onToMap, @
    progressView.once 'ladder', @onLadder, @
    progressView.once 'publish', @onPublish, @
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
    window.tracker?.trackEvent 'Play Level Victory Modal Next Level', category: 'Students', levelSlug: @level.get('slug'), nextLevelSlug: @nextLevel.get('slug'), []
    if me.isSessionless()
      link = "/play/level/#{@nextLevel.get('slug')}?course=#{@courseID}&codeLanguage=#{utils.getQueryVariable('codeLanguage', 'python')}"
    else
      link = "/play/level/#{@nextLevel.get('slug')}?course=#{@courseID}&course-instance=#{@courseInstanceID}"
      link += "&codeLanguage=" + @level.get('primerLanguage') if @level.get('primerLanguage')
    application.router.navigate(link, {trigger: true})

  onStartChallenge: ->
    window.tracker?.trackEvent 'Play Level Victory Modal Start Challenge', category: 'Students', levelSlug: @level.get('slug'), nextAssessmentSlug: @nextAssessment.get('slug'), []
    if me.isSessionless()
      link = "/play/level/#{@nextAssessment.get('slug')}?course=#{@courseID}&codeLanguage=#{utils.getQueryVariable('codeLanguage', 'python')}"
    else
      link = "/play/level/#{@nextAssessment.get('slug')}?course=#{@courseID}&course-instance=#{@courseInstanceID}"
      link += "&codeLanguage=" + @level.get('primerLanguage') if @level.get('primerLanguage')
    application.router.navigate(link, {trigger: true})

  onToMap: ->
    window.tracker?.trackEvent 'Play Level Victory Modal Back to Map', category: 'Students', levelSlug: @level.get('slug'), []
    link = "/play/#{@course.get('campaignID')}?course-instance=#{@courseInstanceID}"
    application.router.navigate(link, {trigger: true})

  onDone: ->
    window.tracker?.trackEvent 'Play Level Victory Modal Done', category: 'Students', levelSlug: @level.get('slug'), []
    if me.isSessionless()
      link = '/teachers/courses'
    else
      link = '/students'
    @submitLadder()
    application.router.navigate(link, {trigger: true})
  
  onPublish: ->
    window.tracker?.trackEvent 'Play Level Victory Modal Publish', category: 'Students', levelSlug: @level.get('slug'), []
    if @session.isFake()
      application.router.navigate(@galleryURL, {trigger: true})
    else
      wasAlreadyPublished = @session.get('published')
      @session.set({ published: true })
      return @session.save().then =>
        application.router.navigate(@galleryURL, {trigger: true})
        text = i18n.t('play_level.project_published_noty')
        unless wasAlreadyPublished
          noty({text, layout: 'topCenter', type: 'success', timeout: 5000})

  onLadder: ->
    # Preserve the supermodel as we navigate back to the ladder.
    viewArgs = [{supermodel: if @options.hasReceivedMemoryWarning then null else @supermodel}, @level.get('slug')]
    ladderURL = "/play/ladder/#{@level.get('slug') || @level.id}"
    if leagueID = (@courseInstanceID or utils.getQueryVariable 'league')
      leagueType = if @level.get('type') is 'course-ladder' then 'course' else 'clan'
      viewArgs.push leagueType
      viewArgs.push leagueID
      ladderURL += "/#{leagueType}/#{leagueID}"
    ladderURL += '#my-matches'
    @submitLadder()
    Backbone.Mediator.publish 'router:navigate', route: ladderURL, viewClass: 'views/ladder/LadderView', viewArgs: viewArgs

  submitLadder: ->
    return if application.testing
    if @level.get('type') is 'course-ladder' and @session.readyToRank() or not @session.inLeague(@courseInstanceID)
      api.levelSessions.submitToRank({ session: @session.id, courseInstanceID: @courseInstanceID })
