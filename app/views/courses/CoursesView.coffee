app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
RootView = require 'views/core/RootView'
template = require 'templates/courses/courses-view'
StudentLogInModal = require 'views/courses/StudentLogInModal'
StudentSignUpModal = require 'views/courses/StudentSignUpModal'
CourseInstance = require 'models/CourseInstance'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
Classroom = require 'models/Classroom'
LevelSession = require 'models/LevelSession'

module.exports = class CoursesView extends RootView
  id: 'courses-view'
  template: template

  events:
    'click #log-in-btn': 'onClickLogInButton'
    'click #start-new-game-btn': 'onClickStartNewGameButton'
    
  initialize: ->
    @courseInstances = new CocoCollection([], { url: "/db/user/#{me.id}/course_instances", model: CourseInstance})
    @courseInstances.comparator = (ci) -> return ci.get('classroomID') + ci.get('courseID')
    @supermodel.loadCollection(@courseInstances, 'course_instances')
    @classrooms = new CocoCollection([], { url: "/db/classroom", model: Classroom })
    @supermodel.loadCollection(@classrooms, 'classrooms', { data: {memberID: me.id} })
    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @supermodel.loadCollection(@courses, 'courses')
    
  onLoaded: ->
    @hocCourseInstance = @courseInstances.findWhere({hourOfCode: true})
    if @hocCourseInstance
      @courseInstances.remove(@hocCourseInstance)
      @sessions = new CocoCollection([], { url: @hocCourseInstance.url() + '/my-course-level-sessions', model: LevelSession })
      @supermodel.loadCollection(@sessions, 'sessions')
    super()
    
  onClickStartNewGameButton: ->
    @openSignUpModal()

  onClickLogInButton: ->
    modal = new StudentLogInModal()
    @openModalView(modal)
    modal.on 'want-to-create-account', @openSignUpModal, @

  openSignUpModal: ->
    modal = new StudentSignUpModal({ willPlay: true })
    @openModalView(modal)
    modal.once 'click-skip-link', @startHourOfCodePlay, @

  startHourOfCodePlay: ->
    @$('#main-content').hide()
    @$('#begin-hoc-area').removeClass('hide')
    hocCourseInstance = new CourseInstance()
    hocCourseInstance.upsertForHOC()
    @listenToOnce hocCourseInstance, 'sync', ->
      url = hocCourseInstance.firstLevelURL()
      app.router.navigate(url, { trigger: true })
