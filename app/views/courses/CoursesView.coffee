app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
RootView = require 'views/core/RootView'
template = require 'templates/courses/courses-view'
StudentLogInModal = require 'views/courses/StudentLogInModal'
StudentSignUpModal = require 'views/courses/StudentSignUpModal'
ChangeCourseLanguageModal = require 'views/courses/ChangeCourseLanguageModal'
ChooseLanguageModal = require 'views/courses/ChooseLanguageModal'
CourseInstance = require 'models/CourseInstance'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
Classroom = require 'models/Classroom'
LevelSession = require 'models/LevelSession'
Campaign = require 'models/Campaign'
utils = require 'core/utils'

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
    @listenToOnce @courseInstances, 'sync', @onCourseInstancesLoaded
    @supermodel.loadCollection(@courseInstances, 'course_instances')
    @classrooms = new CocoCollection([], { url: "/db/classroom", model: Classroom })
    @supermodel.loadCollection(@classrooms, 'classrooms', { data: {memberID: me.id} })
    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @supermodel.loadCollection(@courses, 'courses')
    @campaigns = new CocoCollection([], { url: "/db/campaign", model: Campaign })
    @supermodel.loadCollection(@campaigns, 'campaigns', { data: { type: 'course' }})

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
      @supermodel.loadCollection(courseInstance.sessions, 'sessions', { data: { project: 'state.complete level.original playtime changed' }})

    @hocCourseInstance = @courseInstances.findWhere({hourOfCode: true})
    if @hocCourseInstance
      @courseInstances.remove(@hocCourseInstance)

  onLoaded: ->
    super()
    if utils.getQueryVariable('_cc', false)
      @joinClass()

  onClickStartNewGameButton: ->
    if me.isAnonymous()
      @openSignUpModal()
    else
      modal = new ChooseLanguageModal()
      @openModalView(modal)
      @listenToOnce modal, 'set-language', =>
        @startHourOfCodePlay()
        application.tracker?.trackEvent 'Automatic start hour of code play', category: 'Courses', label: 'set language'
      application.tracker?.trackEvent 'Start New Game', category: 'Courses'

  onClickLogInButton: ->
    modal = new StudentLogInModal()
    @openModalView(modal)
    modal.on 'want-to-create-account', @openSignUpModal, @
    application.tracker?.trackEvent 'Started Student Login', category: 'Courses'

  openSignUpModal: ->
    modal = new StudentSignUpModal({ willPlay: true })
    @openModalView(modal)
    modal.once 'click-skip-link', (=>
      @startHourOfCodePlay()
      application.tracker?.trackEvent 'Automatic start hour of code play', category: 'Courses', label: 'skip link'
      ), @
    application.tracker?.trackEvent 'Started Student Signup', category: 'Courses'

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

  onJoinClassroomSuccess: (newClassroom, jqxhr, options) ->
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
      # join any course instances in the classroom which are free to join
      jqxhrs = []
      for courseInstance in classroomCourseInstances.models
        course = @courses.get(courseInstance.get('courseID'))
        if course.get('free')
          jqxhrs.push = courseInstance.addMember(me.id)
          courseInstance.sessions = new Backbone.Collection()
          @courseInstances.add(courseInstance)
      $.when(jqxhrs...).done =>
        @state = null
        @render()
        location.hash = ''
        f = -> location.hash = '#just-added-text'
        # quick and dirty scroll to just-added classroom
        setTimeout(f, 10)

  onClickChangeLanguageLink: ->
    application.tracker?.trackEvent 'Student clicked change language', category: 'Courses'
    modal = new ChangeCourseLanguageModal()
    @openModalView(modal)
    modal.once 'hidden', @render, @
