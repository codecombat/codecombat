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
store = require 'core/store'
CourseVictoryComponent = require('./CourseVictoryComponent').default
CourseRewardsView = require './CourseRewardsView'
Achievements = require 'collections/Achievements'

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
      @supermodel.trackRequest(@classroom.fetchForCourseInstance(@courseInstanceID, {}))

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
      @levelSessions.fetchForCourseInstance(@courseInstanceID, {})
      @levelSessions = @supermodel.loadCollection(@levelSessions, 'sessions', {
        data: { project: 'state.complete level.original playtime changed' }
      }).model

      if not @course
        @course = new Course()
        @supermodel.trackRequest @course.fetchForCourseInstance(@courseInstanceID, {})

    properties = {
      category: 'Students',
      levelSlug: @level.get('slug')
    }
    concepts = @level.get('goals').filter((g) => g.concepts).map((g) => g.id)
    if concepts.length
      goalStates = @session.get('state').goalStates
      succeededConcepts = concepts.filter((c) => goalStates[c]?.status is 'success')
      _.assign(properties, {concepts, succeededConcepts})

    if @level.isType('hero', 'hero-ladder', 'course', 'course-ladder', 'game-dev', 'web-dev')
      @achievements = options.achievements
      if not @achievements
        @achievements = new Achievements()
        @achievements.fetchRelatedToLevel(@session.get('level').original)
        @achievements = @supermodel.loadCollection(@achievements, 'achievements').model
        @listenToOnce @achievements, 'sync', ->
          @render?()

    window.tracker?.trackEvent 'Play Level Victory Modal Loaded', properties, []
    if @level.isProject()
      @galleryURL = urls.projectGallery({ @courseInstanceID })

  onResourceLoadFailed: (e) ->
    if e.resource.jqxhr is @nextLevelRequest
      return
    super(arguments...)

  onLoaded: ->
    super()
    
    @views = []

    if me.showGemsAndXp() and @achievements.length > 0
      rewardsView = new CourseRewardsView({level: @level, session:@session, achievements:@achievements, supermodel: @supermodel})
      rewardsView.on 'continue', @onViewContinue, @
      @views.push(rewardsView)

    # update level sessions so that stats are correct
    @levelSessions?.remove(@session)
    @levelSessions?.add(@session)

    if @level.isLadder() or @level.isProject()
      @courseID ?= @course.id

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
    
      @views.push(progressView)

    if @views.length > 0
      @showView(_.first(@views))
    else
      @showVictoryComponent() 
      

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
    if @level.isLadder() or @level.isProject()
      index = _.indexOf(@views, @currentView)
      @showView(@views[index+1])
    else
      @showVictoryComponent()
  
  showVictoryComponent: ->
    propsData = {
      nextLevel: @nextLevel.toJSON(),
      nextAssessment: @nextAssessment.toJSON()
      level: @level.toJSON(),
      session: @session.toJSON(),
      course: @course.toJSON(),
      @courseInstanceID,
      stats: @classroom?.statsForSessions(@levelSessions, @course.id)
      supermodel: @supermodel,
      parent: @options.parent
      codeLanguage: @session.get('codeLanguage')
    }
    new CourseVictoryComponent({
      el: @$el.find('.modal-content')[0]
      propsData,
      store
    })

  onNextLevel: ->
    window.tracker?.trackEvent 'Play Level Victory Modal Next Level', category: 'Students', levelSlug: @level.get('slug'), nextLevelSlug: @nextLevel.get('slug'), []
    if me.isSessionless()
      link = "/play/level/#{@nextLevel.get('slug')}?course=#{@courseID}&codeLanguage=#{utils.getQueryVariable('codeLanguage', 'python')}"
    else
      link = "/play/level/#{@nextLevel.get('slug')}?course=#{@courseID}&course-instance=#{@courseInstanceID}"
      link += "&codeLanguage=" + @level.get('primerLanguage') if @level.get('primerLanguage')
    application.router.navigate(link, {trigger: true})

  # TODO: Remove rest of logic transferred to CourseVictoryComponent
  onToMap: ->
    if me.isSessionless()
      link = "/teachers/courses"
    else
      link = "/play/#{@course.get('campaignID')}?course-instance=#{@courseInstanceID}"
    window.tracker?.trackEvent 'Play Level Victory Modal Back to Map', category: 'Students', levelSlug: @level.get('slug'), []
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
      