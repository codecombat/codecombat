require('app/styles/courses/courses-view.sass')
RootView = require 'views/core/RootView'
template = require 'app/templates/courses/courses-view'
AuthModal = require 'views/core/AuthModal'
CreateAccountModal = require 'views/core/CreateAccountModal'
ChangeCourseLanguageModal = require 'views/courses/ChangeCourseLanguageModal'
ChooseLanguageModal = require 'views/courses/ChooseLanguageModal'
JoinClassModal = require 'views/courses/JoinClassModal'
CourseInstance = require 'models/CourseInstance'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
Classroom = require 'models/Classroom'
Classrooms = require 'collections/Classrooms'
Courses = require 'collections/Courses'
CourseInstances = require 'collections/CourseInstances'
LevelSession = require 'models/LevelSession'
Levels = require 'collections/Levels'
NameLoader = require 'core/NameLoader'
Campaign = require 'models/Campaign'
ThangType = require 'models/ThangType'
Mandate = require 'models/Mandate'
store = require 'core/store'
utils = require 'core/utils'
coursesHelper = require 'lib/coursesHelper'

module.exports = class CoursesView extends RootView
  id: 'courses-view'
  template: template

  events:
    'click #log-in-btn': 'onClickLogInButton'
    'click #start-new-game-btn': 'openSignUpModal'
    'click #join-class-btn': 'onClickJoinClassButton'
    'submit #join-class-form': 'onSubmitJoinClassForm'
    'click .play-btn': 'onClickPlay'
    'click .view-class-btn': 'onClickViewClass'
    'click .view-levels-btn': 'onClickViewLevels'
    'click .view-project-gallery-link': 'onClickViewProjectGalleryLink'
    'click .view-challenges-link': 'onClickViewChallengesLink'
    'click .view-videos-link': 'onClickViewVideosLink'

  getMeta: ->
    return {
      title: $.i18n.t('courses.students')
      links: [
        { vmid: 'rel-canonical', rel: 'canonical', href: '/students'}
      ]
    }

  initialize: ->
    super()

    @classCodeQueryVar = utils.getQueryVariable('_cc', false)
    @courseInstances = new CocoCollection([], { url: "/db/user/#{me.id}/course-instances", model: CourseInstance})
    @courseInstances.comparator = (ci) -> return parseInt(ci.get('classroomID'), 16) + utils.orderedCourseIDs.indexOf ci.get('courseID')
    @listenToOnce @courseInstances, 'sync', @onCourseInstancesLoaded
    @supermodel.loadCollection(@courseInstances, { cache: false })
    @classrooms = new CocoCollection([], { url: "/db/classroom", model: Classroom})
    @classrooms.comparator = (a, b) -> b.id.localeCompare(a.id)
    @supermodel.loadCollection(@classrooms, { data: {memberID: me.id}, cache: false })
    @ownedClassrooms = new Classrooms()
    @ownedClassrooms.fetchMine({data: {project: '_id'}})
    @supermodel.trackCollection(@ownedClassrooms)
    @supermodel.addPromiseResource(store.dispatch('courses/fetch'))
    @hourOfCodeOptions = utils.hourOfCodeOptions
    @hocCodeLanguage = (me.get('hourOfCodeOptions') || {}).hocCodeLanguage || 'python'
    @hocStats = {}
    @listenTo @classrooms, 'sync', ->
      if @showHocProgress()
        campaign = @hourOfCodeOptions.campaignId
        sessionFetchOptions = {
          language: @hocCodeLanguage,
          project: 'state.complete,level.original,playtime,changed'
        }
        @supermodel.addPromiseResource(store.dispatch('levelSessions/fetchLevelSessionsForCampaign', {campaignHandle: campaign, options: {data: sessionFetchOptions}}))
        @campaignLevels = new Levels()
        @supermodel.trackRequest(@campaignLevels.fetchForCampaign(@hourOfCodeOptions.campaignId, { data: { project: "original,primerLanguage,slug,i18n.#{me.get('preferredLanguage', true)}" }}))
    @store = store
    @originalLevelMap = {}
    @urls = require('core/urls')

  afterInsert: ->
    super()
    unless me.isStudent() or (@classCodeQueryVar and not me.isTeacher())
      @onClassLoadError()

  onCourseInstancesLoaded: ->
    # HoC 2015 used special single player course instances
    @courseInstances.remove(@courseInstances.where({hourOfCode: true}))

    for courseInstance in @courseInstances.models
      continue if not courseInstance.get('classroomID')
      courseID = courseInstance.get('courseID')
      courseInstance.sessions = new CocoCollection([], {
        url: courseInstance.url() + '/course-level-sessions/' + me.id,
        model: LevelSession
      })
      courseInstance.sessions.comparator = 'changed'
      @supermodel.loadCollection(courseInstance.sessions, { data: { project: 'state.complete,level.original,playtime,changed' }})

  onLoaded: ->
    super()
    if @classCodeQueryVar and not me.isAnonymous()
      window.tracker?.trackEvent 'Students Join Class Link', category: 'Students', classCode: @classCodeQueryVar
      @joinClass()
    else if @classCodeQueryVar and me.isAnonymous()
      @openModalView(new CreateAccountModal())
    ownerIDs = _.map(@classrooms.models, (c) -> c.get('ownerID')) ? []
    Promise.resolve($.ajax(NameLoader.loadNames(ownerIDs)))
    .then(=>
      @ownerNameMap = {}
      @ownerNameMap[ownerID] = NameLoader.getName(ownerID) for ownerID in ownerIDs
      @render?()
    )
    _.forEach _.unique(_.pluck(@classrooms.models, 'id')), (classroomID) =>
      levels = new Levels()
      @listenTo levels, 'sync', =>
        return if @destroyed
        @originalLevelMap[level.get('original')] = level for level in levels.models
        @render()
      @supermodel.trackRequest(levels.fetchForClassroom(classroomID, { data: { project: "original,primerLanguage,slug,i18n.#{me.get('preferredLanguage', true)}" }}))

    if features.china and @classrooms.find {id: '5d0082964ebb960059fc40b2'}
      if new Date() >= new Date(2019, 5, 19, 12) && new Date() <= new Date(2019, 5, 25, 0)
        if window.serverConfig?.currentTournament
          @showTournament = true
        else
          @awaitingTournament = true
          @checkForTournamentStart()

    if @showHocProgress()
      @calculateHocStats()

  showHocProgress: ->
    hocClassrooms = @classrooms.models.find((c) =>
      return c.get('courses').filter((course) => c._id == @hourOfCodeOptions.courseId) && c.get('aceConfig').language == @hocCodeLanguage
    ) || []
    # show showHocProgress if student signed up using the end modal, and there are no relevant classrooms
    if hocClassrooms.length == 0 and (me.get('hourOfCodeOptions') || {}).showHocProgress
      return true

  calculateHocStats: ->
    hocCampaignSessions = (store.getters?['levelSessions/getSessionsForCampaign'](@hourOfCodeOptions.campaignId) || {}).sessions || []
    campaignSessions = _.sortBy(hocCampaignSessions, (s) -> s.changed)
    levelSessionMap = {}
    campaignSessions.forEach((s) => levelSessionMap[s.level.original] = s)
    userLevelStatusMap = {}
    levelsInCampaign = new Set()
    @campaignLevels.models.forEach((l) =>
      if (levelSessionMap[l.get('original')]?.state.complete)
        userLevelStatusMap[l.get('original')] = true
      else
        userLevelStatusMap[l.get('original')] = false
      levelsInCampaign.add(l.get('original'))
    )
    [started, completed, levelsDone] = coursesHelper.hasUserCompletedCourse(userLevelStatusMap, levelsInCampaign)
    @hocStats = {
      complete: completed
      pctDone: (levelsDone / @campaignLevels.models.length * 100).toFixed(1) + '%'
    }

  checkForTournamentStart: =>
    return if @destroyed
    $.get '/db/mandate', (data) =>
      return if @destroyed
      if data?[0]?.currentTournament
        @showTournament = true
        @awaitingTournament = false
        @render()
      else
        setTimeout @checkForTournamentStart, 60 * 1000

  courseInstanceHasProject: (courseInstance) ->
    classroom = @classrooms.get(courseInstance.get('classroomID'))
    versionedCourse = _.find(classroom.get('courses'), {_id: courseInstance.get('courseID')})
    levels = versionedCourse.levels
    _.any(levels, { shareable: 'project' })

  showVideosLinkForCourse: (courseId) ->
    courseId == utils.courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE

  onClickLogInButton: ->
    modal = new AuthModal()
    @openModalView(modal)
    window.tracker?.trackEvent 'Students Login Started', category: 'Students'

  openSignUpModal: ->
    window.tracker?.trackEvent 'Students Signup Started', category: 'Students'
    modal = new CreateAccountModal({ initialValues: { classCode: utils.getQueryVariable('_cc', "") } })
    @openModalView(modal)

  onSubmitJoinClassForm: (e) ->
    e.preventDefault()
    classCode = @$('#class-code-input').val() or @classCodeQueryVar
    window.tracker?.trackEvent 'Students Join Class With Code', category: 'Students', classCode: classCode
    @joinClass()

  onClickJoinClassButton: (e) ->
    classCode = @$('#class-code-input').val() or @classCodeQueryVar
    window.tracker?.trackEvent 'Students Join Class With Code', category: 'Students', classCode: classCode
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

  # Super hacky way to patch users being able to join class while hiding /students from others
  onClassLoadError: ->
    _.defer ->
      application.router.routeDirectly('courses/RestrictedToStudentsView')

  onJoinClassroomError: (classroom, jqxhr, options) ->
    @state = null
    if jqxhr.status is 422
      @errorMessage = 'Please enter a code.'
    else if jqxhr.status is 404
      @errorMessage = $.i18n.t('signup.classroom_not_found')
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
    window.tracker?.trackEvent $(e.currentTarget).data('event-action'), category: 'Students', levelSlug: levelSlug
    application.router.navigate($(e.currentTarget).data('href'), { trigger: true })

  onClickViewClass: (e) ->
    classroomID = $(e.target).data('classroom-id')
    window.tracker?.trackEvent 'Students View Class', category: 'Students', classroomID: classroomID
    application.router.navigate("/students/#{classroomID}", { trigger: true })

  onClickViewLevels: (e) ->
    courseID = $(e.target).data('course-id')
    courseInstanceID = $(e.target).data('courseinstance-id')
    window.tracker?.trackEvent 'Students View Levels', category: 'Students', courseID: courseID, courseInstanceID: courseInstanceID
    application.router.navigate($(e.currentTarget).data('href'), { trigger: true })

  onClickViewProjectGalleryLink: (e) ->
    courseID = $(e.target).data('course-id')
    courseInstanceID = $(e.target).data('courseinstance-id')
    window.tracker?.trackEvent 'Students View To Project Gallery View', category: 'Students', courseID: courseID, courseInstanceID: courseInstanceID
    application.router.navigate("/students/project-gallery/#{courseInstanceID}", { trigger: true })

  onClickViewChallengesLink: (e) ->
    classroomID = $(e.target).data('classroom-id')
    courseID = $(e.target).data('course-id')
    window.tracker?.trackEvent 'Students View To Student Assessments View', category: 'Students', classroomID: classroomID
    application.router.navigate("/students/assessments/#{classroomID}##{courseID}", { trigger: true })

  onClickViewVideosLink: (e) ->
    classroomID = $(e.target).data('classroom-id')
    courseID = $(e.target).data('course-id')
    courseName = $(e.target).data('course-name')
    window.tracker?.trackEvent 'Students View To Videos View', category: 'Students', courseID: courseID, classroomID: classroomID
    application.router.navigate("/students/videos/#{courseID}/#{courseName}", { trigger: true })

  afterRender: ->
    super()
    rulesContent = @$el.find('#tournament-rules-content').html()
    @$el.find('#tournament-rules').popover(placement: 'bottom', trigger: 'hover', container: '#site-content-area', content: rulesContent, html: true)

  tournamentArenas: ->
    if @showTournament
      if /^zh/.test me.get('preferredLanguage', true)
        [
          {
            name: '魔力冲刺'
            id: 'magic-rush'
            image: '/file/db/level/5b3c9e7259cae7002f0a3980/magic-rush-zh-HANS.jpg'
          }
        ]
      else
        [
          {
            name: 'Magic Rush'
            id: 'magic-rush'
            image: '/file/db/level/5b3c9e7259cae7002f0a3980/magic-rush.jpg'
          }
        ]
    else
      []
