app = require 'core/application'
RootView = require 'views/core/RootView'
template = require 'templates/courses/courses-view'
AuthModal = require 'views/core/AuthModal'
CreateAccountModal = require 'views/core/CreateAccountModal'
ChangeCourseLanguageModal = require 'views/courses/ChangeCourseLanguageModal'
ChooseLanguageModal = require 'views/courses/ChooseLanguageModal'
CourseInstance = require 'models/CourseInstance'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
Classroom = require 'models/Classroom'
Classrooms = require 'collections/Classrooms'
LevelSession = require 'models/LevelSession'
Campaign = require 'models/Campaign'
utils = require 'core/utils'

# TODO: Test everything

module.exports = class CoursesView extends RootView
  id: 'courses-view'
  template: template

  events:
    'click #log-in-btn': 'onClickLogInButton'
    'click #start-new-game-btn': 'openSignUpModal'
    'click #join-class-btn': 'onClickJoinClassButton'
    'submit #join-class-form': 'onSubmitJoinClassForm'
    'click #change-language-link': 'onClickChangeLanguageLink'

  initialize: ->
    @courseInstances = new CocoCollection([], { url: "/db/user/#{me.id}/course_instances", model: CourseInstance})
    @courseInstances.comparator = (ci) -> return ci.get('classroomID') + ci.get('courseID')
    @listenToOnce @courseInstances, 'sync', @onCourseInstancesLoaded
    @supermodel.loadCollection(@courseInstances)
    @classrooms = new CocoCollection([], { url: "/db/classroom", model: Classroom })
    @supermodel.loadCollection(@classrooms, { data: {memberID: me.id} })
    @ownedClassrooms = new Classrooms()
    @ownedClassrooms.fetchMine({data: {project: '_id'}})
    @supermodel.trackCollection(@ownedClassrooms)
    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @supermodel.loadCollection(@courses)

  onCourseInstancesLoaded: ->
    map = {}
    for courseInstance in @courseInstances.models
      courseID = courseInstance.get('courseID')
      if map[courseID]
        courseInstance.sessions = map[courseID]
        continue
      map[courseID] = courseInstance.sessions = new CocoCollection([], {
        url: courseInstance.url() + '/my-course-level-sessions',
        model: LevelSession
      })
      courseInstance.sessions.comparator = 'changed'
      @supermodel.loadCollection(courseInstance.sessions, { data: { project: 'state.complete level.original playtime changed' }})

    hocCourseInstance = @courseInstances.findWhere({hourOfCode: true})
    if hocCourseInstance
      @courseInstances.remove(hocCourseInstance)

  onLoaded: ->
    super()
    if utils.getQueryVariable('_cc', false) and not me.isAnonymous()
      @joinClass()

  onClickLogInButton: ->
    modal = new AuthModal()
    @openModalView(modal)
    application.tracker?.trackEvent 'Started Student Login', category: 'Courses'

  openSignUpModal: ->
    modal = new CreateAccountModal({ initialValues: { classCode: utils.getQueryVariable('_cc', "") } })
    @openModalView(modal)
    application.tracker?.trackEvent 'Started Student Signup', category: 'Courses'

  onSubmitJoinClassForm: (e) ->
    e.preventDefault()
    @joinClass()

  onClickJoinClassButton: (e) ->
    @joinClass()

  joinClass: ->
    return if @state
    @state = 'enrolling'
    @errorMessage = null
    @classCode = @$('#class-code-input').val() or utils.getQueryVariable('_cc', false)
    if not @classCode
      @state = null
      @errorMessage = 'Please enter a code.'
      @renderSelectors '#join-class-form'
      return
    @renderSelectors '#join-class-form'
    newClassroom = new Classroom()
    newClassroom.joinWithCode(@classCode)
    newClassroom.on 'sync', @onJoinClassroomSuccess, @
    newClassroom.on 'error', @onJoinClassroomError, @

  onJoinClassroomError: (classroom, jqxhr, options) ->
    @state = null
    application.tracker?.trackEvent 'Failed to join classroom with code', category: 'Courses', status: jqxhr.status
    if jqxhr.status is 422
      @errorMessage = 'Please enter a code.'
    else if jqxhr.status is 404
      @errorMessage = 'Code not found.'
    else
      @errorMessage = "#{jqxhr.responseText}"
    @renderSelectors '#join-class-form'

  onJoinClassroomSuccess: (newClassroom, data, options) ->
    application.tracker?.trackEvent 'Joined classroom', {
      category: 'Courses'
      classCode: @classCode
      classroomID: newClassroom.id
      classroomName: newClassroom.get('name')
      ownerID: newClassroom.get('ownerID')
    }
    @classrooms.add(newClassroom)
    @render()
    @classroomJustAdded = newClassroom.id

    classroomCourseInstances = new CocoCollection([], { url: "/db/course_instance", model: CourseInstance })
    classroomCourseInstances.fetch({ data: {classroomID: newClassroom.id} })
    @listenToOnce classroomCourseInstances, 'sync', ->
      # TODO: Smoother system for joining a classroom and course instances, without requiring page reload,
      # and showing which class was just joined. 
      document.location.search = '' # Using document.location.reload() causes an infinite loop of reloading
    
  onClickChangeLanguageLink: ->
    application.tracker?.trackEvent 'Student clicked change language', category: 'Courses'
    modal = new ChangeCourseLanguageModal()
    @openModalView(modal)
    modal.once 'hidden', @render, @
