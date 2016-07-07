Course = require 'models/Course'
Courses = require 'collections/Courses'
LevelSessions = require 'collections/LevelSessions'
CourseInstance = require 'models/CourseInstance'
CourseInstances = require 'collections/CourseInstances'
Classroom = require 'models/Classroom'
Classrooms = require 'collections/Classrooms'
Levels = require 'collections/Levels'
RootView = require 'views/core/RootView'
template = require 'templates/courses/course-details'
User = require 'models/User'
storage = require 'core/storage'

module.exports = class CourseDetailsView extends RootView
  id: 'course-details-view'
  template: template
  teacherMode: false
  memberSort: 'nameAsc'

  events:
    'click .btn-play-level': 'onClickPlayLevel'
    'click .btn-select-instance': 'onClickSelectInstance'
    'submit #school-form': 'onSubmitSchoolForm'

  constructor: (options, @courseID, @courseInstanceID) ->
    super options
    @ownedClassrooms = new Classrooms()
    @courses = new Courses()
    @course = new Course()
    @levelSessions = new LevelSessions()
    @courseInstance = new CourseInstance({_id: @courseInstanceID})
    @owner = new User()
    @classroom = new Classroom()
    @levels = new Levels()
    @courseInstances = new CourseInstances()

    @supermodel.trackRequest @ownedClassrooms.fetchMine({data: {project: '_id'}})
    @supermodel.trackRequest(@courses.fetch().then(=>
      @course = @courses.get(@courseID)
    ))
    sessionsLoaded = @supermodel.trackRequest(@levelSessions.fetchForCourseInstance(@courseInstanceID, {cache: false}))

    @supermodel.trackRequest(@courseInstance.fetch().then(=>
      return if @destroyed
      @teacherMode = @courseInstance.get('ownerID') is me.id

      @owner = new User({_id: @courseInstance.get('ownerID')})
      @supermodel.trackRequest(@owner.fetch())

      classroomID = @courseInstance.get('classroomID')
      @classroom = new Classroom({ _id: classroomID })
      @supermodel.trackRequest(@classroom.fetch())

      levelsLoaded = @supermodel.trackRequest(@levels.fetchForClassroomAndCourse(classroomID, @courseID, {
        data: { project: 'concepts,practice,type,slug,name,original,description' }
      }))

      @supermodel.trackRequest($.when(levelsLoaded, sessionsLoaded).then(=>
        @buildSessionStats()
        return if @destroyed
        if @memberStats[me.id]?.totalLevelsCompleted >= @levels.size() - 1  # Don't need to complete arena
          # need to figure out the next course instance
          @courseComplete = true
          @courseInstances.comparator = 'courseID'
          # TODO: make this logic use locked course content to figure out the next course, then fetch the 
          # course instance for that
          @supermodel.trackRequest(@courseInstances.fetchForClassroom(classroomID).then(=>
            @nextCourseInstance = _.find @courseInstances.models, (ci) => ci.get('courseID') > @courseID
            if @nextCourseInstance
              nextCourseID = @nextCourseInstance.get('courseID')
              @nextCourse = @courses.get(nextCourseID)
        ))
        @promptForSchool = @courseComplete and not me.isAnonymous() and not me.get('schoolName') and not storage.load('no-school')
      ))
    ))

  initialize: (options) ->
    window.tracker?.trackEvent 'Students Class Course Loaded', category: 'Students', ['Mixpanel']
    super(options)

  buildSessionStats: ->
    return if @destroyed

    @levelConceptMap = {}
    for level in @levels.models
      @levelConceptMap[level.get('original')] ?= {}
      for concept in level.get('concepts')
        @levelConceptMap[level.get('original')][concept] = true
      if level.get('type') is 'course-ladder'
        @arenaLevel = level

    # console.log 'onLevelSessionsSync'
    @memberStats = {}
    @userConceptStateMap = {}
    @userLevelStateMap = {}
    for levelSession in @levelSessions.models
      continue if levelSession.skipMe   # Don't track second arena session as another completed level
      userID = levelSession.get('creator')
      levelID = levelSession.get('level').original
      state = if levelSession.get('state')?.complete then 'complete' else 'started'
      playtime = parseInt(levelSession.get('playtime') ? 0, 10)
      do (userID, levelID) =>
        secondSessionForLevel = _.find(@levelSessions.models, ((otherSession) ->
          otherSession.get('creator') is userID and otherSession.get('level').original is levelID and otherSession.id isnt levelSession.id
        ))
        if secondSessionForLevel
          state = 'complete' if secondSessionForLevel.get('state')?.complete
          playtime = playtime + parseInt(secondSessionForLevel.get('playtime') ? 0, 10)
          secondSessionForLevel.skipMe = true

      @memberStats[userID] ?= totalLevelsCompleted: 0, totalPlayTime: 0
      @memberStats[userID].totalLevelsCompleted++ if state is 'complete'
      @memberStats[userID].totalPlayTime += playtime

      @userConceptStateMap[userID] ?= {}
      for concept of @levelConceptMap[levelID]
        @userConceptStateMap[userID][concept] = state

      @userLevelStateMap[userID] ?= {}
      @userLevelStateMap[userID][levelID] = state

    @conceptsCompleted = {}
    for userID, conceptStateMap of @userConceptStateMap
      for concept, state of conceptStateMap
        @conceptsCompleted[concept] ?= 0
        @conceptsCompleted[concept]++
        
  onClickPlayLevel: (e) ->
    levelSlug = $(e.target).closest('.btn-play-level').data('level-slug')
    levelID = $(e.target).closest('.btn-play-level').data('level-id')
    level = @levels.findWhere({original: levelID})
    window.tracker?.trackEvent 'Students Class Course Play Level', category: 'Students', courseID: @courseID, courseInstanceID: @courseInstanceID, levelSlug: levelSlug, ['Mixpanel']
    if level.get('type') is 'course-ladder'
      viewClass = 'views/ladder/LadderView'
      viewArgs = [{supermodel: @supermodel}, levelSlug]
      route = '/play/ladder/' + levelSlug
      route += '/course/' + @courseInstance.id
      viewArgs = viewArgs.concat ['course', @courseInstance.id]
    else
      route = @getLevelURL levelSlug
      viewClass = 'views/play/level/PlayLevelView'
      viewArgs = [{courseID: @courseID, courseInstanceID: @courseInstanceID, supermodel: @supermodel}, levelSlug]
    Backbone.Mediator.publish 'router:navigate', route: route, viewClass: viewClass, viewArgs: viewArgs

  getLevelURL: (levelSlug) ->
    "/play/level/#{levelSlug}?course=#{@courseID}&course-instance=#{@courseInstanceID}"

  getOwnerName: ->
    return if @owner.isNew()
    if @owner.get('firstName') and @owner.get('lastName')
      return "#{@owner.get('firstName')} #{@owner.get('lastName')}"
    @owner.get('name') or @owner.get('email')

  getLastLevelCompleted: ->
    lastLevelCompleted = null
    for levelID in @levels.pluck('original')
      if @userLevelStateMap?[me.id]?[levelID] is 'complete'
        lastLevelCompleted = levelID
    return lastLevelCompleted
