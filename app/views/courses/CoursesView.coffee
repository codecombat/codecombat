app = require 'core/application'
RootView = require 'views/core/RootView'
template = require 'templates/courses/courses-view'
AuthModal = require 'views/core/AuthModal'
CreateAccountModal = require 'views/core/CreateAccountModal'
ChangeCourseLanguageModal = require 'views/courses/ChangeCourseLanguageModal'
HeroSelectModal = require 'views/courses/HeroSelectModal'
ChooseLanguageModal = require 'views/courses/ChooseLanguageModal'
JoinClassModal = require 'views/courses/JoinClassModal'
CourseInstance = require 'models/CourseInstance'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
Classroom = require 'models/Classroom'
Classrooms = require 'collections/Classrooms'
LevelSession = require 'models/LevelSession'
Campaign = require 'models/Campaign'
ThangType = require 'models/ThangType'
utils = require 'core/utils'

# TODO: Test everything

module.exports = class CoursesView extends RootView
  id: 'courses-view'
  template: template

  events:
    'click #log-in-btn': 'onClickLogInButton'
    'click #start-new-game-btn': 'openSignUpModal'
    'click .change-hero-btn': 'onClickChangeHeroButton'
    'click #join-class-btn': 'onClickJoinClassButton'
    'submit #join-class-form': 'onSubmitJoinClassForm'
    'click .play-btn': 'onClickPlay'
    'click .view-class-btn': 'onClickViewClass'
    'click .view-levels-btn': 'onClickViewLevels'

  getTitle: -> return $.i18n.t('teacher.students')

  initialize: ->
    @classCodeQueryVar = utils.getQueryVariable('_cc', false)
    @courseInstances = new CocoCollection([], { url: "/db/user/#{me.id}/course_instances", model: CourseInstance})
    @courseInstances.comparator = (ci) -> return ci.get('classroomID') + ci.get('courseID')
    @listenToOnce @courseInstances, 'sync', @onCourseInstancesLoaded
    @supermodel.loadCollection(@courseInstances, { cache: false })
    @classrooms = new CocoCollection([], { url: "/db/classroom", model: Classroom })
    @supermodel.loadCollection(@classrooms, { data: {memberID: me.id}, cache: false })
    @ownedClassrooms = new Classrooms()
    @ownedClassrooms.fetchMine({data: {project: '_id'}})
    @supermodel.trackCollection(@ownedClassrooms)
    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @supermodel.loadCollection(@courses)

    # TODO: Trim this section for only what's necessary
    @hero = new ThangType
    defaultHeroOriginal = ThangType.heroes.captain
    heroOriginal = me.get('heroConfig')?.thangType or defaultHeroOriginal
    @hero.url = "/db/thang.type/#{heroOriginal}/version"
    # @hero.setProjection ['name','slug','soundTriggers','featureImages','gems','heroClass','description','components','extendedName','unlockLevelName','i18n']
    @supermodel.loadModel(@hero, 'hero')
    @listenTo @hero, 'all', ->
      @render()
    window.tracker?.trackEvent 'Students Loaded', category: 'Students', ['Mixpanel']
    
  afterInsert: ->
    super()
    unless me.isStudent() or (@classCodeQueryVar and not me.isTeacher())
      @onClassLoadError()

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
    if @classCodeQueryVar and not me.isAnonymous()
      window.tracker?.trackEvent 'Students Join Class Link', category: 'Students', classCode: @classCodeQueryVar, ['Mixpanel']
      @joinClass()
    else if @classCodeQueryVar and me.isAnonymous()
      @openModalView(new CreateAccountModal())

  onClickLogInButton: ->
    modal = new AuthModal()
    @openModalView(modal)
    window.tracker?.trackEvent 'Students Login Started', category: 'Students', ['Mixpanel']

  openSignUpModal: ->
    window.tracker?.trackEvent 'Students Signup Started', category: 'Students', ['Mixpanel']
    modal = new CreateAccountModal({ initialValues: { classCode: utils.getQueryVariable('_cc', "") } })
    @openModalView(modal)

  onClickChangeHeroButton: ->
    window.tracker?.trackEvent 'Students Change Hero Started', category: 'Students', ['Mixpanel']
    modal = new HeroSelectModal({ currentHeroID: @hero.id })
    @openModalView(modal)
    @listenTo modal, 'hero-select:success', (newHero) =>
      # @hero.url = "/db/thang.type/#{me.get('heroConfig').thangType}/version"
      # @hero.fetch()
      @hero.set(newHero.attributes)
    @listenTo modal, 'hide', ->
      @stopListening modal

  onSubmitJoinClassForm: (e) ->
    e.preventDefault()
    classCode = @$('#class-code-input').val() or @classCodeQueryVar
    window.tracker?.trackEvent 'Students Join Class With Code', category: 'Students', classCode: classCode, ['Mixpanel']
    @joinClass()

  onClickJoinClassButton: (e) ->
    classCode = @$('#class-code-input').val() or @classCodeQueryVar
    window.tracker?.trackEvent 'Students Join Class With Code', category: 'Students', classCode: classCode, ['Mixpanel']
    @joinClass()

  joinClass: ->
    return if @state
    @state = 'enrolling'
    @errorMessage = null
    @classCode = @$('#class-code-input').val() or @classCodeQueryVar
    if not @classCode
      @state = null
      @errorMessage = 'Please enter a code.'
      @renderSelectors '#join-class-form'
      return
    @renderSelectors '#join-class-form'
    if me.get('emailVerified') or me.isStudent()
      newClassroom = new Classroom()
      jqxhr = newClassroom.joinWithCode(@classCode)
      @listenTo newClassroom, 'join:success', -> @onJoinClassroomSuccess(newClassroom)
      @listenTo newClassroom, 'join:error', -> @onJoinClassroomError(newClassroom, jqxhr)
    else
      modal = new JoinClassModal({ @classCode })
      @openModalView modal
      @listenTo modal, 'error', @onClassLoadError
      @listenTo modal, 'join:success', @onJoinClassroomSuccess
      @listenTo modal, 'join:error', @onJoinClassroomError
      @listenToOnce modal, 'hidden', ->
        unless me.isStudent()
          @onClassLoadError()
      @listenTo modal, 'hidden', ->
        @state = null
        @renderSelectors '#join-class-form'

  # Super hacky way to patch users being able to join class while hiding /courses from others
  onClassLoadError: ->
    _.defer ->
      application.router.routeDirectly('courses/RestrictedToStudentsView')

  onJoinClassroomError: (classroom, jqxhr, options) ->
    @state = null
    if jqxhr.status is 422
      @errorMessage = 'Please enter a code.'
    else if jqxhr.status is 404
      @errorMessage = $.t('signup.classroom_not_found')
    else
      @errorMessage = "#{jqxhr.responseText}"
    @renderSelectors '#join-class-form'

  onJoinClassroomSuccess: (newClassroom, data, options) ->
    @state = null
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

  onClickPlay: (e) ->
    levelSlug = $(e.currentTarget).data('level-slug')
    window.tracker?.trackEvent $(e.currentTarget).data('event-action'), category: 'Students', levelSlug: levelSlug, ['Mixpanel']
    application.router.navigate($(e.currentTarget).data('href'), { trigger: true })

  onClickViewClass: (e) ->
    classroomID = $(e.target).data('classroom-id')
    window.tracker?.trackEvent 'Students View Class', category: 'Students', classroomID: classroomID, ['Mixpanel']
    application.router.navigate("/courses/#{classroomID}", { trigger: true })

  onClickViewLevels: (e) ->
    courseID = $(e.target).data('course-id')
    courseInstanceID = $(e.target).data('courseinstance-id')
    window.tracker?.trackEvent 'Students View Levels', category: 'Students', courseID: courseID, courseInstanceID: courseInstanceID, ['Mixpanel']
    application.router.navigate("/courses/#{courseID}/#{courseInstanceID}", { trigger: true })
