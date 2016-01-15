Campaign = require 'models/Campaign'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
CourseInstance = require 'models/CourseInstance'
Classroom = require 'models/Classroom'
LevelSession = require 'models/LevelSession'
RootView = require 'views/core/RootView'
template = require 'templates/courses/course-details'
User = require 'models/User'
storage = require 'core/storage'

module.exports = class CourseDetailsView extends RootView
  id: 'course-details-view'
  template: template
  teacherMode: false
  singlePlayerMode: false
  memberSort: 'nameAsc'

  events:
    'click .btn-play-level': 'onClickPlayLevel'
    'click .btn-select-instance': 'onClickSelectInstance'
    'submit #school-form': 'onSubmitSchoolForm'

  constructor: (options, @courseID, @courseInstanceID) ->
    super options
    @courseID ?= options.courseID
    @courseInstanceID ?= options.courseInstanceID
    @classroom = new Classroom()
    @course = @supermodel.getModel(Course, @courseID) or new Course _id: @courseID
    @listenTo @course, 'sync', @onCourseSync
    if @course.loaded
      @onCourseSync()
    else
      @supermodel.loadModel @course, 'course'

  getRenderData: ->
    context = super()
    context.campaign = @campaign
    context.course = @course if @course?.loaded
    context.courseInstance = @courseInstance if @courseInstance?.loaded
    context.courseInstances = @courseInstances?.models ? []
    context.levelConceptMap = @levelConceptMap ? {}
    context.noCourseInstance = @noCourseInstance
    context.noCourseInstanceSelected = @noCourseInstanceSelected
    context.userLevelStateMap = @userLevelStateMap ? {}
    context.promptForSchool = @courseComplete and not me.isAnonymous() and not me.get('schoolName') and not storage.load('no-school')
    context

  afterRender: ->
    super()
    if @supermodel.finished() and @courseComplete and me.isAnonymous() and @options.justBeatLevel
      # TODO: Make an intermediate modal that tells them they've finished HoC and has some snazzy stuff for convincing players to sign up instead of just throwing up the bare AuthModal
      AuthModal = require 'views/core/AuthModal'
      @openModalView new AuthModal showSignupRationale: true

  onCourseSync: ->
    return if @destroyed
    # console.log 'onCourseSync'
    if me.isAnonymous() and (not me.get('hourOfCode') and not @course.get('hourOfCode'))
      @noCourseInstance = true
      @render()
      return
    return if @campaign?
    campaignID = @course.get('campaignID')
    @campaign = @supermodel.getModel(Campaign, campaignID) or new Campaign _id: campaignID
    @listenTo @campaign, 'sync', @onCampaignSync
    if @campaign.loaded
      @onCampaignSync()
    else
      @supermodel.loadModel @campaign, 'campaign'
    @render()

  onCampaignSync: ->
    return if @destroyed
    # console.log 'onCampaignSync'
    if @courseInstanceID
      @loadCourseInstance(@courseInstanceID)
    else unless me.isAnonymous()
      @loadCourseInstances()
    @levelConceptMap = {}
    for levelID, level of @campaign.get('levels')
      @levelConceptMap[levelID] ?= {}
      for concept in level.concepts
        @levelConceptMap[levelID][concept] = true
      if level.type is 'course-ladder'
        @arenaLevel = level
    @render()

  loadCourseInstances: ->
    @courseInstances = new CocoCollection [], {url: "/db/user/#{me.id}/course_instances", model: CourseInstance, comparator: 'courseID'}
    @listenToOnce @courseInstances, 'sync', @onCourseInstancesSync
    @supermodel.loadCollection @courseInstances, 'course_instances'

  loadAllCourses: ->
    @allCourses = new CocoCollection [], {url: "/db/course", model: Course, comparator: '_id'}
    @listenToOnce @allCourses, 'sync', @onAllCoursesSync
    @supermodel.loadCollection @allCourses, 'courses'

  loadCourseInstance: (courseInstanceID) ->
    return if @destroyed
    # console.log 'loadCourseInstance'
    return if @courseInstance?
    @courseInstanceID = courseInstanceID
    @courseInstance = @supermodel.getModel(CourseInstance, @courseInstanceID) or new CourseInstance _id: @courseInstanceID
    @listenTo @courseInstance, 'sync', @onCourseInstanceSync
    if @courseInstance.loaded
      @onCourseInstanceSync()
    else
      @courseInstance = @supermodel.loadModel(@courseInstance, 'course_instance').model

  onCourseInstancesSync: ->
    return if @destroyed
    # console.log 'onCourseInstancesSync'
    @findNextCourseInstance()
    if not @courseInstance
      # We are loading these to find the one we want to display.
      if @courseInstances.models.length is 1
        @loadCourseInstance(@courseInstances.models[0].id)
      else
        if @courseInstances.models.length is 0
          @noCourseInstance = true
        else
          @noCourseInstanceSelected = true
        @render()

  onCourseInstanceSync: ->
    return if @destroyed
    # console.log 'onCourseInstanceSync'
    if @courseInstance.get('classroomID')
      @classroom = new Classroom({_id: @courseInstance.get('classroomID')})
      @supermodel.loadModel @classroom, 'classroom'
    @singlePlayerMode = @courseInstance.get('name') is 'Single Player'
    @teacherMode = @courseInstance.get('ownerID') is me.id and not @singlePlayerMode
    @levelSessions = new CocoCollection([], { url: "/db/course_instance/#{@courseInstance.id}/level_sessions", model: LevelSession, comparator: '_id' })
    @listenToOnce @levelSessions, 'sync', @onLevelSessionsSync
    @supermodel.loadCollection @levelSessions, 'level_sessions', cache: false
    @owner = new User({_id: @courseInstance.get('ownerID')})
    @supermodel.loadModel @owner, 'user'
    @render()

  onLevelSessionsSync: ->
    return if @destroyed
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

    if @memberStats[me.id]?.totalLevelsCompleted >= _.size(@campaign.get('levels')) - 1  # Don't need to complete arena
      @courseComplete = true
      @loadCourseInstances() unless @courseInstances  # Find the next course instance to do.

    @render()

  onAllCoursesSync: ->
    @findNextCourseInstance()

  findNextCourseInstance: ->
    @nextCourseInstance = _.find @courseInstances.models, (ci) =>
      # Sorted by courseID
      ci.get('classroomID') is @courseInstance.get('classroomID') and ci.id isnt @courseInstance.id and ci.get('courseID') > @course.id
    if @nextCourseInstance
      nextCourseID = @nextCourseInstance.get('courseID')
      @nextCourse = @supermodel.getModel(Course, nextCourseID) or new Course _id: nextCourseID
      @nextCourse = @supermodel.loadModel(@nextCourse, 'course').model
    else if @allCourses?.loaded
      @nextCourse = _.find @allCourses.models, (course) => course.id > @course.id
    else
      @loadAllCourses()

  onClickPlayLevel: (e) ->
    levelSlug = $(e.target).closest('.btn-play-level').data('level-slug')
    levelID = $(e.target).closest('.btn-play-level').data('level-id')
    level = @campaign.get('levels')[levelID]
    if level.type is 'course-ladder'
      viewClass = 'views/ladder/LadderView'
      viewArgs = [{supermodel: @supermodel}, levelSlug]
      route = '/play/ladder/' + levelSlug
      unless @singlePlayerMode  # No league for solo courses
        route += '/course/' + @courseInstance.id
        viewArgs = viewArgs.concat ['course', @courseInstance.id]
    else
      route = @getLevelURL levelSlug
      viewClass = 'views/play/level/PlayLevelView'
      viewArgs = [{courseID: @courseID, courseInstanceID: @courseInstanceID, supermodel: @supermodel}, levelSlug]
    Backbone.Mediator.publish 'router:navigate', route: route, viewClass: viewClass, viewArgs: viewArgs

  getLevelURL: (levelSlug) ->
    "/play/level/#{levelSlug}?course=#{@courseID}&course-instance=#{@courseInstanceID}"

  onClickSelectInstance: (e) ->
    courseInstanceID = $('.select-instance').val()
    @noCourseInstanceSelected = false
    @loadCourseInstance(courseInstanceID)

  getOwnerName: ->
    return if @owner.isNew()
    if @owner.get('firstName') and @owner.get('lastName')
      return "#{@owner.get('firstName')} #{@owner.get('lastName')}"
    @owner.get('name') or @owner.get('email')

  onSubmitSchoolForm: (e) ->
    e.preventDefault()
    schoolName = @$el.find('#course-complete-school-input').val().trim()
    if schoolName and schoolName isnt me.get('schoolName')
      me.set 'schoolName', schoolName
      me.patch()
    else
      storage.save 'no-school', true
    @$el.find('#school-form').slideUp('slow')

  getLastLevelCompleted: ->
    lastLevelCompleted = null
    for levelID in _.keys(@campaign.get('levels'))
      if @userLevelStateMap?[me.id]?[levelID] is 'complete'
        lastLevelCompleted = levelID
    return lastLevelCompleted
