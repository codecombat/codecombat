app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
RootView = require 'views/core/RootView'
template = require 'templates/courses/courses-view'
StudentLogInModal = require 'views/courses/StudentLogInModal'
StudentSignUpModal = require 'views/courses/StudentSignUpModal'
ChangeCourseLanguageModal = require 'views/courses/ChangeCourseLanguageModal'
CourseInstance = require 'models/CourseInstance'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
Classroom = require 'models/Classroom'
LevelSession = require 'models/LevelSession'
Campaign = require 'models/Campaign'

# TODO: Test everything

module.exports = class CoursesView extends RootView
  id: 'courses-view'
  template: template

  events:
    'click #log-in-btn': 'onClickLogInButton'
    'click #start-new-game-btn': 'onClickStartNewGameButton'
    'click #join-class-btn': 'onClickJoinClassButton'
    'submit #join-class-form': 'onSubmitJoinClassForm'
    'click #change-language-link': 'onClickChangeLanguageLink'
  
  initialize: ->
    @courseInstances = new CocoCollection([], { url: "/db/user/#{me.id}/course_instances", model: CourseInstance})
    @courseInstances.comparator = (ci) -> return ci.get('classroomID') + ci.get('courseID')
    @supermodel.loadCollection(@courseInstances, 'course_instances')
    @classrooms = new CocoCollection([], { url: "/db/classroom", model: Classroom })
    @supermodel.loadCollection(@classrooms, 'classrooms', { data: {memberID: me.id} })
    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @supermodel.loadCollection(@courses, 'courses')
    @campaigns = new CocoCollection([], { url: "/db/campaign", model: Campaign })
    @supermodel.loadCollection(@campaigns, 'campaigns', { data: { type: 'course' }})

  onLoaded: ->
    for courseInstance in @courseInstances.models
      # TODO: fetch sessions for given course instance
      # TODO: make sure we only fetch one per courseID
      courseInstance.sessions = new CocoCollection([], { url: '???', model: LevelSession })
      courseInstance.sessions.allDone = ->
        # TODO: should return if all non-arena courses are complete
      
    @hocCourseInstance = @courseInstances.findWhere({hourOfCode: true})
    if @hocCourseInstance
      @courseInstances.remove(@hocCourseInstance)
      @sessions = new CocoCollection([], { url: @hocCourseInstance.url() + '/my-course-level-sessions', model: LevelSession })
      @sessions.comparator = 'changed'
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

  onSubmitJoinClassForm: (e) ->
    e.preventDefault()
    @joinClass()
      
  onClickJoinClassButton: (e) ->
    @joinClass()

  joinClass: ->
    @state = 'enrolling'
    @classCode = @$('#classroom-code-input').val() or utils.getQueryVariable('_cc', false)
    return unless @classCode
    @renderSelectors '#join-classroom-form'
    newClassroom = new Classroom()
    newClassroom.joinWithCode(@classCode)
    newClassroom.on 'sync', @onJoinClassroomSuccess, @
    newClassroom.on 'error', @onJoinClassroomError, @

  onJoinClassroomError: (classroom, jqxhr, options) ->
    application.tracker?.trackEvent 'Failed to join classroom with code', status: jqxhr.status
    @state = 'unknown_error'
    if jqxhr.status is 422
      @errorMessage = 'Please enter a code.'
    else if jqxhr.status is 404
      @errorMessage = 'Code not found.'
    else
      @errorMessage = "#{jqxhr.responseText}"
    @renderSelectors '#join-classroom-form'    

  onJoinClassroomSuccess: (newClassroom, jqxhr, options) ->
    application.tracker?.trackEvent 'Joined classroom', {
      classroomID: newClassroom.id,
      classroomName: newClassroom.get('name')
      ownerID: newClassroom.get('ownerID')
    }
    @classrooms.add(newClassroom)
    newClassroom.justAdded = true
    @render()
    
    classroomCourseInstances = new CocoCollection([], { url: "/db/course_instance", model: CourseInstance })
    classroomCourseInstances.fetch({ data: {classroomID: classroom.id} })
    @listenToOnce classroomCourseInstances, 'sync', ->
      # join any course instances in the classroom which are free to join
      jqxhrs = []
      for courseInstance in classroomCourseInstances.models
        course = @courses.get(courseInstance.get('courseID'))
        if course.get('free')
          jqxhrs.push = courseInstance.addMember(me.id)
          @courseInstances.add(courseInstance)
      $.when(jqxhrs...).done =>
        @state = ''
        @render()
        delete newClassroom.justAdded
        
  onClickChangeLanguageLink: ->
    modal = new ChangeCourseLanguageModal()
    @openModalView(modal)