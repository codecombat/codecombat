require('app/styles/courses/classroom-view.sass')
Campaign = require 'models/Campaign'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
CourseInstance = require 'models/CourseInstance'
Classroom = require 'models/Classroom'
Classrooms = require 'collections/Classrooms'
LevelSession = require 'models/LevelSession'
Prepaids = require 'collections/Prepaids'
Levels = require 'collections/Levels'
RootView = require 'views/core/RootView'
template = require 'templates/courses/classroom-view'
User = require 'models/User'
utils = require 'core/utils'
Prepaid = require 'models/Prepaid'
ClassroomSettingsModal = require 'views/courses/ClassroomSettingsModal'
ActivateLicensesModal = require 'views/courses/ActivateLicensesModal'
InviteToClassroomModal = require 'views/courses/InviteToClassroomModal'
RemoveStudentModal = require 'views/courses/RemoveStudentModal'
popoverTemplate = require 'templates/courses/classroom-level-popover'

module.exports = class ClassroomView extends RootView
  id: 'classroom-view'
  template: template
  teacherMode: false

  events:
    'click #edit-class-details-link': 'onClickEditClassDetailsLink'
    'click #activate-licenses-btn': 'onClickActivateLicensesButton'
    'click .activate-single-license-btn': 'onClickActivateSingleLicenseButton'
    'click #add-students-btn': 'onClickAddStudentsButton'
    'click .enable-btn': 'onClickEnableButton'
    'click .remove-student-link': 'onClickRemoveStudentLink'

  initialize: (options, classroomID) ->
    return if me.isAnonymous()
    @classroom = new Classroom({_id: classroomID})
    @supermodel.loadModel @classroom
    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @courses.comparator = '_id'
    @supermodel.loadCollection(@courses)
    @courses.comparator = '_id'
    @courseInstances = new CocoCollection([], { url: "/db/course_instance", model: CourseInstance})
    @courseInstances.comparator = 'courseID'
    @supermodel.loadCollection(@courseInstances, { data: { classroomID: classroomID } })
    @prepaids = new Prepaids()
    @prepaids.comparator = '_id'
    @prepaids.fetchByCreator(me.id)
    @supermodel.loadCollection(@prepaids)
    @users = new CocoCollection([], { url: "/db/classroom/#{classroomID}/members?memberLimit=100", model: User })
    @users.comparator = (user) => user.broadName().toLowerCase()
    @supermodel.loadCollection(@users)
    @listenToOnce @courseInstances, 'sync', @onCourseInstancesSync
    @sessions = new CocoCollection([], { model: LevelSession })
    @ownedClassrooms = new Classrooms()
    @ownedClassrooms.fetchMine({data: {project: '_id'}})
    @supermodel.trackCollection(@ownedClassrooms)
    @levels = new Levels()
    @levels.fetchForClassroom(classroomID, {data: {project: 'name,original,practice,slug'}})
    @levels.on 'add', (model) -> @_byId[model.get('original')] = model # so you can 'get' them
    @supermodel.trackCollection(@levels)
    window.tracker?.trackEvent 'Students Class Loaded', category: 'Students', classroomID: classroomID, ['Mixpanel']

  onCourseInstancesSync: ->
    @sessions = new CocoCollection([], { model: LevelSession })
    for courseInstance in @courseInstances.models
      sessions = new CocoCollection([], { url: "/db/course_instance/#{courseInstance.id}/level_sessions", model: LevelSession })
      @supermodel.loadCollection(sessions, { data: { project: ['level', 'playtime', 'creator', 'changed', 'state.complete'].join(' ') } })
      courseInstance.sessions = sessions
      sessions.courseInstance = courseInstance
      courseInstance.sessionsByUser = {}
      @listenToOnce sessions, 'sync', (sessions) ->
        @sessions.add(sessions.slice())
        for courseInstance in @courseInstances.models
          courseInstance.sessionsByUser = courseInstance.sessions.groupBy('creator')

    # Generate course instance JIT, in the meantime have models w/out equivalents in the db
    for course in @courses.models
      query = {courseID: course.id, classroomID: @classroom.id}
      courseInstance = @courseInstances.findWhere(query)
      if not courseInstance
        courseInstance = new CourseInstance(query)
        @courseInstances.add(courseInstance)
        courseInstance.sessions = new CocoCollection([], {model: LevelSession})
        sessions.courseInstance = courseInstance
        courseInstance.sessionsByUser = {}

  onLoaded: ->
    @teacherMode = me.isAdmin() or @classroom.get('ownerID') is me.id
    userSessions = @sessions.groupBy('creator')
    for user in @users.models
      user.sessions = new CocoCollection(userSessions[user.id], { model: LevelSession })
      user.sessions.comparator = 'changed'
      user.sessions.sort()
    for courseInstance in @courseInstances.models
      courseID = courseInstance.get('courseID')
      course = @courses.get(courseID)
      courseInstance.sessions.course = course
    super()

  afterRender: ->
    @$('[data-toggle="popover"]').popover({
      html: true
      trigger: 'hover'
      placement: 'top'
    })
    super()

  onClickActivateLicensesButton: ->
    modal = new ActivateLicensesModal({
      classroom: @classroom
      users: @users
    })
    @openModalView(modal)
    modal.once 'redeem-users', -> document.location.reload()
    application.tracker?.trackEvent 'Classroom started enroll students', category: 'Courses'

  onClickActivateSingleLicenseButton: (e) ->
    userID = $(e.target).closest('.btn').data('user-id')
    if @prepaids.totalMaxRedeemers() - @prepaids.totalRedeemers() > 0
      # Have an unused enrollment, enroll student immediately instead of opening the enroll modal
      prepaid = @prepaids.find((prepaid) -> prepaid.status() is 'available')
      $.ajax({
        method: 'POST'
        url: _.result(prepaid, 'url') + '/redeemers'
        data: { userID: userID }
        success: =>
          application.tracker?.trackEvent 'Classroom finished enroll student', category: 'Courses', userID: userID
          # TODO: do a lighter refresh here. @render() did not work out.
          document.location.reload()
        error: (jqxhr, textStatus, errorThrown) ->
          if jqxhr.status is 402
            message = arguments[2]
          else
            message = "#{jqxhr.status}: #{jqxhr.responseText}"
          console.err message
      })
    else
      user = @users.get(userID)
      modal = new ActivateLicensesModal({
        classroom: @classroom
        users: @users
        user: user
      })
      @openModalView(modal)
      modal.once 'redeem-users', -> document.location.reload()
      application.tracker?.trackEvent 'Classroom started enroll student', category: 'Courses', userID: userID

  onClickEditClassDetailsLink: ->
    modal = new ClassroomSettingsModal({classroom: @classroom})
    @openModalView(modal)
    @listenToOnce modal, 'hidden', @render

  userLastPlayedString: (user) ->
    return '' unless user.sessions?
    session = user.sessions.last()
    return '' unless session
    course = session.collection.course
    levelOriginal = session.get('level').original
    level = @levels.findWhere({original: levelOriginal})
    lastPlayed = ""
    lastPlayed += course.get('name') if course
    lastPlayed += ", #{level.get('name')}" if level
    lastPlayed

  userPlaytimeString: (user) ->
    return '' unless user.sessions?
    playtime = _.reduce user.sessions.pluck('playtime'), (s1, s2) -> (s1 or 0) + (s2 or 0)
    return '' unless playtime
    return moment.duration(playtime, 'seconds').humanize()

  classStats: ->
    stats = {}

    playtime = 0
    total = 0
    for session in @sessions.models
      pt = session.get('playtime') or 0
      playtime += pt
      total += 1
    stats.averagePlaytime = if playtime and total then moment.duration(playtime / total, "seconds").humanize() else 0
    stats.totalPlaytime = if playtime then moment.duration(playtime, "seconds").humanize() else 0

    levelPracticeMap = {}
    levelPracticeMap[level.id] = level.get('practice') ? false for level in @levels.models
    completeSessions = @sessions.filter (s) -> s.get('state')?.complete and not levelPracticeMap[s.get('levelID')]
    stats.averageLevelsComplete = if @users.size() then (_.size(completeSessions) / @users.size()).toFixed(1) else 'N/A'  # '
    stats.totalLevelsComplete = _.size(completeSessions)

    enrolledUsers = @users.filter (user) -> user.isEnrolled()
    stats.enrolledUsers = _.size(enrolledUsers)
    return stats

  onClickAddStudentsButton: (e) ->
    modal = new InviteToClassroomModal({classroom: @classroom})
    @openModalView(modal)
    application.tracker?.trackEvent 'Classroom started add students', category: 'Courses', classroomID: @classroom.id

  onClickEnableButton: (e) ->
    $button = $(e.target).closest('.btn')
    courseInstance = @courseInstances.get($button.data('course-instance-cid'))
    console.log 'looking for course instance', courseInstance, 'for', $button.data('course-instance-cid'), 'out of', @courseInstances
    userID = $button.data('user-id')
    $button.attr('disabled', true)
    application.tracker?.trackEvent 'Course assign student', category: 'Courses', courseInstanceID: courseInstance.id, userID: userID

    onCourseInstanceCreated = =>
      courseInstance.addMember(userID)
      @listenToOnce courseInstance, 'sync', @render

    if courseInstance.isNew()
      # adding the first student to this course, so generate the course instance for it
      if not courseInstance.saving
        courseInstance.save(null, {validate: false})
        courseInstance.saving = true
      courseInstance.once 'sync', onCourseInstanceCreated
    else
      onCourseInstanceCreated()

    # TODO: update newly visible level progress bar (currently all white)

  onClickRemoveStudentLink: (e) ->
    user = @users.get($(e.target).closest('a').data('user-id'))
    modal = new RemoveStudentModal({
      classroom: @classroom
      user: user
      courseInstances: @courseInstances
    })
    @openModalView(modal)
    modal.once 'remove-student', @onStudentRemoved, @

  onStudentRemoved: (e) ->
    @users.remove(e.user)
    @render()
    application.tracker?.trackEvent 'Classroom removed student', category: 'Courses', classroomID: @classroom.id, userID: e.user.id

  levelPopoverContent: (level, session, i) ->
    return null unless level
    context = {
      moment: moment
      level: level
      session: session
      i: i
      canViewSolution: @teacherMode
    }
    return popoverTemplate(context)

  getLevelURL: (level, course, courseInstance, session) ->
    return null unless @teacherMode and _.all(arguments)
    "/play/level/#{level.get('slug')}?course=#{course.id}&course-instance=#{courseInstance.id}&session=#{session.id}&observing=true"
