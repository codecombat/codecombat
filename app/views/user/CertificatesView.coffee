require('app/styles/user/certificates-view.sass')
RootView = require 'views/core/RootView'
User = require 'models/User'
Classroom = require 'models/Classroom'
Course = require 'models/Course'
CourseInstance = require 'models/CourseInstance'
LevelSessions = require 'collections/LevelSessions'
Levels = require 'collections/Levels'
ThangTypeConstants = require 'lib/ThangTypeConstants'
utils = require 'core/utils'
fetchJson = require 'core/api/fetch-json'

module.exports = class CertificatesView extends RootView
  id: 'certificates-view'
  template: require 'templates/user/certificates-view'

  events:
    #'click .back-btn': 'onClickBackButton'
    'click .print-btn': 'onClickPrintButton'

  getTitle: -> 'Certificates'  # TODO: put student name in

  initialize: (options, @userID) ->
    if @userID is me.id
      @user = me
      @setHero()
    else
      @user = new User _id: @userID
      @user.fetch()
      @supermodel.trackModel @user
      @listenToOnce @user, 'sync', @setHero
    if classroomID = utils.getQueryVariable 'class'
      @classroom = new Classroom _id: classroomID
      @classroom.fetch()
      @supermodel.trackModel @classroom
      @listenToOnce @classroom, 'sync', @fetchTeacher
    if courseID = utils.getQueryVariable 'course'
      @course = new Course _id: courseID
      @course.fetch()
      @supermodel.trackModel @course
    @courseInstanceID = utils.getQueryVariable 'course-instance'
    # TODO: anonymous loading of classrooms and courses with just enough info to generate cert, or cert route on server
    # TODO: handle when we don't have classroom & course
    # TODO: add a check here that the course is completed

    @sessions = new LevelSessions()
    @supermodel.trackRequest @sessions.fetchForCourseInstance @courseInstanceID, userID: @userID, data: { project: 'state.complete,level.original,playtime,changed,code,codeLanguage,team' }
    @listenToOnce @sessions, 'sync', @calculateStats
    @courseLevels = new Levels()
    @supermodel.trackRequest @courseLevels.fetchForClassroomAndCourse classroomID, courseID, data: { project: 'concepts,practice,assessment,primerLanguage,type,slug,name,original,description,shareable,i18n,thangs.id,thangs.components.config.programmableMethods' }
    @listenToOnce @courseLevels, 'sync', @calculateStats

  setHero: ->
    @heroThangType = @user.get('heroConfig')?.thangType or ThangTypeConstants.heroes.captain
    # TODO: actually fetch the ThangType
    # TODO: grab pose images and add signature images for heroes

  fetchTeacher: ->
    @teacher = new User _id: @classroom.get 'ownerID'
    @teacher.fetch()
    @supermodel.trackModel @teacher

  calculateStats: ->
    return unless @sessions.loaded and @courseLevels.loaded
    @courseStats = @classroom.statsForSessions @sessions, @course.id, @courseLevels
    if @courseStats.levels.project
      projectSession = @sessions.find (session) => session.get('level').original is @courseStats.levels.project.get('original')
      if projectSession
        @projectLink = "#{window.location.origin}/play/#{@courseStats.levels.project.get('type')}-level/#{projectSession.id}"
        fetchJson('/db/level.session/short-link', method: 'POST', json: {url: @projectLink}).then (response) =>
          @projectShortLink = response.shortLink
          @render()

  #onClickBackButton: ->
  #  application.router.openView(@options.backView)

  onClickPrintButton: ->
    window.print()
