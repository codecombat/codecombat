require('app/styles/courses/teacher-class-view.sass')
RootView = require 'views/core/RootView'
State = require 'models/State'
helper = require 'lib/coursesHelper'
utils = require 'core/utils'
ClassroomSettingsModal = require 'views/courses/ClassroomSettingsModal'
InviteToClassroomModal = require 'views/courses/InviteToClassroomModal'
ActivateLicensesModal = require 'views/courses/ActivateLicensesModal'
EditStudentModal = require 'views/teachers/EditStudentModal'
RemoveStudentModal = require 'views/courses/RemoveStudentModal'
CoursesNotAssignedModal = require './CoursesNotAssignedModal'
CourseNagSubview = require 'views/teachers/CourseNagSubview'

viewContentTemplate = require 'templates/courses/teacher-class-view'
viewContentTemplateWithLayout = require 'templates/courses/teacher-class-view-full'

Campaigns = require 'collections/Campaigns'
Classroom = require 'models/Classroom'
Classrooms = require 'collections/Classrooms'
Levels = require 'collections/Levels'
LevelSession = require 'models/LevelSession'
LevelSessions = require 'collections/LevelSessions'
User = require 'models/User'
Users = require 'collections/Users'
Course = require 'models/Course'
Courses = require 'collections/Courses'
CourseInstance = require 'models/CourseInstance'
CourseInstances = require 'collections/CourseInstances'
Prepaids = require 'collections/Prepaids'
window.saveAs ?= require 'file-saver/FileSaver.js' # `window.` is necessary for spec to spy on it
window.saveAs = window.saveAs.saveAs if window.saveAs.saveAs  # Module format changed with webpack?
TeacherClassAssessmentsTable = require('./TeacherClassAssessmentsTable').default
PieChart = require('core/components/PieComponent').default
GoogleClassroomHandler = require('core/social-handlers/GoogleClassroomHandler')

{ STARTER_LICENSE_COURSE_IDS } = require 'core/constants'

module.exports = class TeacherClassView extends RootView
  id: 'teacher-class-view'
  helper: helper

  events:
    'click .nav-tabs a': 'onClickNavTabLink'
    'click .unarchive-btn': 'onClickUnarchive'
    'click .edit-classroom': 'onClickEditClassroom'
    'click .add-students-btn': 'onClickAddStudents'
    'click .edit-student-link': 'onClickEditStudentLink'
    'click .sort-button': 'onClickSortButton'
    'click #copy-url-btn': 'onClickCopyURLButton'
    'click #copy-code-btn': 'onClickCopyCodeButton'
    'click .remove-student-link': 'onClickRemoveStudentLink'
    'click .assign-student-button': 'onClickAssignStudentButton'
    'click .enroll-student-button': 'onClickEnrollStudentButton'
    'click .revoke-student-button': 'onClickRevokeStudentButton'
    'click .revoke-all-students-button': 'onClickRevokeAllStudentsButton'
    'click .assign-to-selected-students': 'onClickBulkAssign'
    'click .remove-from-selected-students': 'onClickBulkRemoveCourse'
    'click .export-student-progress-btn': 'onClickExportStudentProgress'
    'click .select-all': 'onClickSelectAll'
    'click .student-checkbox': 'onClickStudentCheckbox'
    'keyup #student-search': 'onKeyPressStudentSearch'
    'change .course-select, .bulk-course-select': 'onChangeCourseSelect'
    'click a.student-level-progress-dot': 'onClickStudentProgressDot'
    'click .sync-google-classroom-btn': 'onClickSyncGoogleClassroom'

  getInitialState: ->
    {
      sortValue: 'name'
      sortDirection: 1
      activeTab: '#' + (Backbone.history.getHash() or 'students-tab')
      students: new Users()
      classCode: ""
      joinURL: ""
      errors:
        nobodySelected: false
      selectedCourse: undefined
      checkboxStates: {}
      classStats:
        averagePlaytime: ""
        totalPlaytime: ""
        averageLevelsComplete: ""
        totalLevelsComplete: ""
        enrolledUsers: ""
    }

  getTitle: -> return @classroom?.get('name')

  initialize: (options, classroomID) ->
    super(options)

    if (options.renderOnlyContent)
      @template = viewContentTemplate
    else
      @template = viewContentTemplateWithLayout

    # wrap templates so they translate when called
    translateTemplateText = (template, context) => $('<div />').html(template(context)).i18n().html()
    @singleStudentCourseProgressDotTemplate = _.wrap(require('templates/teachers/hovers/progress-dot-single-student-course'), translateTemplateText)
    @singleStudentLevelProgressDotTemplate = _.wrap(require('templates/teachers/hovers/progress-dot-single-student-level'), translateTemplateText)
    @allStudentsLevelProgressDotTemplate = _.wrap(require('templates/teachers/hovers/progress-dot-all-students-single-level'), translateTemplateText)

    @urls = require('core/urls')

    @debouncedRender = _.debounce @render
    @calculateProgressAndLevels = _.debounce @calculateProgressAndLevelsAux, 800

    @state = new State(@getInitialState())

    if options.readOnly
      @state.set('readOnly', options.readOnly)
    if options.renderOnlyContent
      @state.set('renderOnlyContent', options.renderOnlyContent)

    @updateHash @state.get('activeTab') # TODO: Don't push to URL history (maybe don't use url fragment for default tab)

    @classroom = new Classroom({ _id: classroomID })
    @supermodel.trackRequest @classroom.fetch()
    @onKeyPressStudentSearch = _.debounce(@onKeyPressStudentSearch, 200)
    @sortedCourses = []
    @latestReleasedCourses = []

    @prepaids = new Prepaids()
    @supermodel.trackRequest @prepaids.fetchMineAndShared()

    @students = new Users()
    @classroom.sessions = new LevelSessions()
    @listenTo @classroom, 'sync', ->
      @fetchStudents()
      @fetchSessions()

    @students.comparator = (student1, student2) =>
      dir = @state.get('sortDirection')
      value = @state.get('sortValue')
      if value is 'name'
        return (if student1.broadName().toLowerCase() < student2.broadName().toLowerCase() then -dir else dir)

      if value is 'progress'
        # TODO: I would like for this to be in the Level model,
        #   but it doesn't know about its own courseNumber.
        level1 = student1.latestCompleteLevel
        level2 = student2.latestCompleteLevel
        return -dir if not level1
        return dir if not level2
        return dir * (level1.courseNumber - level2.courseNumber or level1.levelNumber - level2.levelNumber)

      if value is 'status'
        statusMap = { expired: 0, 'not-enrolled': 1, enrolled: 2 }
        diff = statusMap[student1.prepaidStatus()] - statusMap[student2.prepaidStatus()]
        return dir * diff if diff
        return (if student1.broadName().toLowerCase() < student2.broadName().toLowerCase() then -dir else dir)

    @courses = new Courses()
    @supermodel.trackRequest @courses.fetch()

    @courseInstances = new CourseInstances()
    @supermodel.trackRequest @courseInstances.fetchForClassroom(classroomID)

    @levels = new Levels()
    @supermodel.trackRequest @levels.fetchForClassroom(classroomID, {data: {project: 'original,name,primaryConcepts,concepts,primerLanguage,practice,shareable,i18n,assessment,assessmentPlacement,slug,goals'}})
    me.getClientCreatorPermissions()?.then(() => @debouncedRender?())
    @attachMediatorEvents()
    window.tracker?.trackEvent 'Teachers Class Loaded', category: 'Teachers', classroomID: @classroom.id, ['Mixpanel']

  fetchStudents: ->
    Promise.all(@students.fetchForClassroom(@classroom, {removeDeleted: true, data: {project: 'firstName,lastName,name,email,coursePrepaid,coursePrepaidID,deleted'}}))
    .then =>
      return if @destroyed
      @removeDeletedStudents() # TODO: Move this to mediator listeners?
      @calculateProgressAndLevels()
      @debouncedRender?()

  fetchSessions: ->
    Promise.all(@classroom.sessions.fetchForAllClassroomMembers(@classroom))
    .then =>
      return if @destroyed
      @removeDeletedStudents() # TODO: Move this to mediator listeners?
      @calculateProgressAndLevels()
      @debouncedRender?()

  attachMediatorEvents: () ->
    # Model/Collection events
    @listenTo @classroom, 'sync change update', ->
      classCode = @classroom.get('codeCamel') or @classroom.get('code')
      @state.set {
        classCode: classCode
        joinURL: document.location.origin + "/students?_cc=" + classCode
      }
      @sortedCourses = @classroom.getSortedCourses()
      @availableCourseMap = {}
      @availableCourseMap[course._id] = true for course in @sortedCourses
      @debouncedRender()
    @listenTo @courses, 'sync change update', ->
      @setCourseMembers() # Is this necessary?
      unless @state.get 'selectedCourse'
        @state.set 'selectedCourse', @courses.first()
      @setSelectedCourseInstance()
    @listenTo @courseInstances, 'sync change update', ->
      @setCourseMembers()
      @setSelectedCourseInstance()
    @listenTo @students, 'sync change update add remove reset', ->
      # Set state/props of things that depend on students?
      # Set specific parts of state based on the models, rather than just dumping the collection there?
      @calculateProgressAndLevels()
      @state.set students: @students
      checkboxStates = {}
      for student in @students.models
        checkboxStates[student.id] = @state.get('checkboxStates')[student.id] or false
      @state.set { checkboxStates }
    @listenTo @students, 'sort', ->
      @state.set students: @students
    @listenTo @, 'course-select:change', ({ selectedCourse }) ->
      @state.set selectedCourse: selectedCourse
    @listenTo @state, 'change:selectedCourse', (e) ->
      @setSelectedCourseInstance()

  setCourseMembers: =>
    for course in @courses.models
      course.instance = @courseInstances.findWhere({ courseID: course.id, classroomID: @classroom.id })
      course.members = course.instance?.get('members') or []
    null

  setSelectedCourseInstance: ->
    selectedCourse = @state.get('selectedCourse') or @courses.first()
    if selectedCourse
      @state.set 'selectedCourseInstance', @courseInstances.findWhere courseID: selectedCourse.id, classroomID: @classroom.id
    else if @state.get 'selectedCourseInstance'
      @state.set 'selectedCourseInstance', null

  onLoaded: ->
    # Get latest courses for student assignment dropdowns
    @latestReleasedCourses = if me.isAdmin() then @courses.models else @courses.where({releasePhase: 'released'})
    @latestReleasedCourses = utils.sortCoursesByAcronyms(@latestReleasedCourses)
    @removeDeletedStudents() # TODO: Move this to mediator listeners? For both classroom and students?
    @calculateProgressAndLevels()

    # render callback setup
    @listenTo @courseInstances, 'sync change update', @debouncedRender
    @listenTo @state, 'sync change', ->
      if _.isEmpty(_.omit(@state.changed, 'searchTerm'))
        @renderSelectors('#license-status-table')
      else
        @debouncedRender()
    @listenTo @students, 'sort', @debouncedRender
    @getCourseAssessmentPairs()
    super()

  afterRender: ->
    super(arguments...)
    unless @courseNagSubview
      @courseNagSubview = new CourseNagSubview()
      @insertSubView(@courseNagSubview)

    if @classroom.hasAssessments()
      levels = []
      course = @state.get('selectedCourse')
      if course and not @classroom.hasAssessments({courseId: course.id})
        course = @courses.find((c) => @classroom.hasAssessments({courseId: c.id}))
      if course
        levels = _.find(@courseAssessmentPairs, (pair) -> pair[0] is course)?[1] || []
        levels = levels.map((l) => l.toJSON())
        courseInstance = @courseInstances.findWhere({ courseID: course.id, classroomID: @classroom.id })
        if courseInstance
          courseInstance = courseInstance.toJSON()
      students = @state.get('students').toJSON()

      propsData = {
        students
        levels,
        course: course?.toJSON(),
        progress: @state.get('progressData')?.get({ @classroom, course }),
        courseInstance,
        classroom: @classroom.toJSON(),
        readOnly: @state.get('readOnly')
      }
      new TeacherClassAssessmentsTable({
        el: @$el.find('.assessments-table')[0]
        propsData
      })
      new PieChart({
        el: @$el.find('.pie')[0]
        propsData: {
          percent: 100*2/3,
          'strokeWidth': 10,
          color: "#20572B",
          opacity: 1
        }
      })
    $('.progress-dot, .btn-view-project-level').each (i, el) ->
      dot = $(el)
      dot.tooltip({
        html: true
      }).delegate '.tooltip', 'mousemove', ->
        dot.tooltip('hide')

  allStatsLoaded: ->
    @classroom?.loaded and @classroom?.get('members')?.length is 0 or (@students?.loaded and @classroom?.sessions?.loaded)

  calculateProgressAndLevelsAux: ->
    return if @destroyed
    return unless @supermodel.progress is 1 and @allStatsLoaded()
    userLevelCompletedMap = @classroom.sessions.models.reduce((map, session) =>
      if session.completed()
        map[session.get('creator')] ?= {}
        map[session.get('creator')][session.get('level').original.toString()] = true
      map
    , {})
    # TODO: How to structure this in @state?
    for student in @students.models
      # TODO: this is a weird hack
      studentsStub = new Users([ student ])
      student.latestCompleteLevel = helper.calculateLatestComplete(@classroom, @courses, @courseInstances, studentsStub, userLevelCompletedMap)
    earliestIncompleteLevel = helper.calculateEarliestIncomplete(@classroom, @courses, @courseInstances, @students)
    latestCompleteLevel = helper.calculateLatestComplete(@classroom, @courses, @courseInstances, @students, userLevelCompletedMap)

    classroomsStub = new Classrooms([ @classroom ])
    progressData = helper.calculateAllProgress(classroomsStub, @courses, @courseInstances, @students)
    # conceptData: helper.calculateConceptsCovered(classroomsStub, @courses, @campaigns, @courseInstances, @students)

    @state.set {
      earliestIncompleteLevel
      latestCompleteLevel
      progressData
      classStats: @calculateClassStats()
    }

  getCourseAssessmentPairs: () ->
    @courseAssessmentPairs = []
    for course in @courses.models
      assessmentLevels = @classroom.getLevels({courseID: course.id, assessmentLevels: true}).models
      fullLevels = _.filter(@levels.models, (l) => l.get('original') in _.map(assessmentLevels, (l2)=>l2.get('original')))
      @courseAssessmentPairs.push([course, fullLevels])
    return @courseAssessmentPairs

  onClickNavTabLink: (e) ->
    e.preventDefault()
    hash = $(e.target).closest('a').attr('href')
    if hash isnt window.location.hash
      tab = hash.slice(1)
      window.tracker?.trackEvent 'Teachers Class Switch Tab', { category: 'Teachers', classroomID: @classroom.id, tab }, ['Mixpanel']
    @updateHash(hash)
    @state.set activeTab: hash

  updateHash: (hash) ->
    return if application.testing
    window.location.hash = hash

  onClickCopyCodeButton: ->
    window.tracker?.trackEvent 'Teachers Class Copy Class Code', category: 'Teachers', classroomID: @classroom.id, classCode: @state.get('classCode'), ['Mixpanel']
    @$('#join-code-input').val(@state.get('classCode')).select()
    @tryCopy()

  onClickCopyURLButton: ->
    window.tracker?.trackEvent 'Teachers Class Copy Class URL', category: 'Teachers', classroomID: @classroom.id, url: @state.get('joinURL'), ['Mixpanel']
    @$('#join-url-input').val(@state.get('joinURL')).select()
    @tryCopy()

  onClickUnarchive: ->
    return unless me.id is @classroom.get('ownerID') # May be viewing page as admin
    window.tracker?.trackEvent 'Teachers Class Unarchive', category: 'Teachers', classroomID: @classroom.id, ['Mixpanel']
    @classroom.save { archived: false }

  onClickEditClassroom: (e) ->
    return unless me.id is @classroom.get('ownerID') # May be viewing page as admin
    window.tracker?.trackEvent 'Teachers Class Edit Class Started', category: 'Teachers', classroomID: @classroom.id, ['Mixpanel']
    @promptToEdit()

  promptToEdit: () ->
    classroom = @classroom
    modal = new ClassroomSettingsModal({ classroom: classroom })
    @openModalView(modal)
    @listenToOnce modal, 'hide', @render

  onClickEditStudentLink: (e) ->
    return unless me.id is @classroom.get('ownerID') # May be viewing page as admin
    window.tracker?.trackEvent 'Teachers Class Students Edit', category: 'Teachers', classroomID: @classroom.id, ['Mixpanel']
    user = @students.get($(e.currentTarget).data('student-id'))
    modal = new EditStudentModal({ user, @classroom })
    @openModalView(modal)

  onClickRemoveStudentLink: (e) ->
    return unless me.id is @classroom.get('ownerID') # May be viewing page as admin
    user = @students.get($(e.currentTarget).data('student-id'))
    modal = new RemoveStudentModal({
      classroom: @classroom
      user: user
      courseInstances: @courseInstances
    })
    @openModalView(modal)
    modal.once 'remove-student', @onStudentRemoved, @

  onStudentRemoved: (e) ->
    @students.remove(e.user)
    window.tracker?.trackEvent 'Teachers Class Students Removed', category: 'Teachers', classroomID: @classroom.id, userID: e.user.id, ['Mixpanel']

  onClickAddStudents: (e) =>
    return unless me.id is @classroom.get('ownerID') # May be viewing page as admin
    window.tracker?.trackEvent 'Teachers Class Add Students', category: 'Teachers', classroomID: @classroom.id, ['Mixpanel']
    modal = new InviteToClassroomModal({ classroom: @classroom })
    @openModalView(modal)
    @listenToOnce modal, 'hide', @render

  removeDeletedStudents: () ->
    return unless @classroom.loaded and @students.loaded
    return unless me.id is @classroom.get('ownerID') # May be viewing page as admin
    _.remove(@classroom.get('members'), (memberID) =>
      not @students.get(memberID) or @students.get(memberID)?.get('deleted')
    )
    true

  onClickSortButton: (e) ->
    value = $(e.target).val()
    if value is @state.get('sortValue')
      @state.set('sortDirection', -@state.get('sortDirection'))
    else
      @state.set({
        sortValue: value
        sortDirection: 1
      })
    @students.sort()

  onKeyPressStudentSearch: (e) ->
    @state.set('searchTerm', $(e.target).val())

  onChangeCourseSelect: (e) ->
    @trigger 'course-select:change', { selectedCourse: @courses.get($(e.currentTarget).val()) }

  getSelectedStudentIDs: ->
    Object.keys(_.pick @state.get('checkboxStates'), (checked) -> checked)

  ensureInstance: (courseID) ->

  onClickEnrollStudentButton: (e) ->
    return unless me.id is @classroom.get('ownerID') # May be viewing page as admin
    userID = $(e.currentTarget).data('user-id')
    user = @students.get(userID)
    selectedUsers = new Users([user])
    @enrollStudents(selectedUsers)
    window.tracker?.trackEvent $(e.currentTarget).data('event-action'), category: 'Teachers', classroomID: @classroom.id, userID: userID, ['Mixpanel']

  enrollStudents: (selectedUsers) ->
    return unless me.id is @classroom.get('ownerID') # May be viewing page as admin
    modal = new ActivateLicensesModal { @classroom, selectedUsers, users: @students }
    @openModalView(modal)
    modal.once 'redeem-users', (enrolledUsers) =>
      enrolledUsers.each (newUser) =>
        user = @students.get(newUser.id)
        if user
          user.set(newUser.attributes)
      null

  onClickExportStudentProgress: ->
    # TODO: Does not yield .csv download on Safari, and instead opens a new tab with the .csv contents
    window.tracker?.trackEvent 'Teachers Class Export CSV', category: 'Teachers', classroomID: @classroom.id, ['Mixpanel']
    courseLabels = ""
    courses = (@courses.get(c._id) for c in @sortedCourses)
    courseLabelsArray = helper.courseLabelsArray(courses)
    for course, index in courses
      courseLabels += "#{courseLabelsArray[index]} Levels,#{courseLabelsArray[index]} Playtime,"
    csvContent = "Name,Username,Email,Total Levels,Total Playtime,#{courseLabels}Concepts\n"
    levelCourseIdMap = {}
    levelPracticeMap = {}
    language = @classroom.get('aceConfig')?.language
    for trimCourse in @classroom.getSortedCourses()
      for trimLevel in trimCourse.levels
        continue if language and trimLevel.primerLanguage is language
        if trimLevel.practice
          levelPracticeMap[trimLevel.original] = true
          continue
        levelCourseIdMap[trimLevel.original] = trimCourse._id
    for student in @students.models
      concepts = []
      for trimCourse in @classroom.getSortedCourses()
        course = @courses.get(trimCourse._id)
        instance = @courseInstances.findWhere({ courseID: course.id, classroomID: @classroom.id })
        if instance and instance.hasMember(student)
          for trimLevel in trimCourse.levels
            level = @levels.findWhere({ original: trimLevel.original })
            continue if level.get('assessment')
            progress = @state.get('progressData').get({ classroom: @classroom, course: course, level: level, user: student })
            concepts.push(level.get('concepts') ? []) if progress?.completed
      concepts = _.union(_.flatten(concepts))
      conceptsString = _.map(concepts, (c) -> $.i18n.t("concepts." + c)).join(', ')
      courseCountsMap = {}
      levels = 0
      playtime = 0
      for session in @classroom.sessions.models
        continue unless session.get('creator') is student.id
        continue unless session.get('state')?.complete
        continue if levelPracticeMap[session.get('level')?.original]
        level = @levels.findWhere({ original: session.get('level')?.original })
        continue if level?.get('assessment')
        levels++
        playtime += session.get('playtime') or 0
        if courseID = levelCourseIdMap[session.get('level')?.original]
          courseCountsMap[courseID] ?= {levels: 0, playtime: 0}
          courseCountsMap[courseID].levels++
          courseCountsMap[courseID].playtime += session.get('playtime') or 0
      playtimeString = if playtime is 0 then "0" else moment.duration(playtime, 'seconds').humanize()
      for course in @sortedCourses
        courseCountsMap[course._id] ?= {levels: 0, playtime: 0}
      courseCounts = []
      for course in @sortedCourses
        courseID = course._id
        data = courseCountsMap[courseID]
        courseCounts.push
          id: courseID
          levels: data.levels
          playtime: data.playtime
      utils.sortCourses(courseCounts)
      courseCountsString = ""
      for counts, index in courseCounts
        courseCountsString += "#{counts.levels},"
        if counts.playtime is 0
          courseCountsString += "0,"
        else
          courseCountsString += "#{moment.duration(counts.playtime, 'seconds').humanize()},"
      csvContent += "#{student.broadName()},#{student.get('name')},#{student.get('email') or ''},#{levels},#{playtimeString},#{courseCountsString}\"#{conceptsString}\"\n"
    csvContent = csvContent.substring(0, csvContent.length - 1)
    file = new Blob([csvContent], {type: 'text/csv;charset=utf-8'})
    window.saveAs(file, 'CodeCombat.csv')

  onClickAssignStudentButton: (e) ->
    return unless me.id is @classroom.get('ownerID') # May be viewing page as admin
    userID = $(e.currentTarget).data('user-id')
    user = @students.get(userID)
    members = [userID]
    courseID = $(e.currentTarget).data('course-id')
    @assignCourse courseID, members
    window.tracker?.trackEvent 'Teachers Class Students Assign Selected', category: 'Teachers', classroomID: @classroom.id, courseID: courseID, userID: userID, ['Mixpanel']

  onClickBulkAssign: ->
    return unless me.id is @classroom.get('ownerID') # May be viewing page as admin
    courseID = @$('.bulk-course-select').val()
    selectedIDs = @getSelectedStudentIDs()
    nobodySelected = selectedIDs.length is 0
    @state.set errors: { nobodySelected }
    return if nobodySelected
    @assignCourse courseID, selectedIDs
    window.tracker?.trackEvent 'Teachers Class Students Assign Selected', category: 'Teachers', classroomID: @classroom.id, courseID: courseID, ['Mixpanel']

  onClickBulkRemoveCourse: ->
    return unless me.id is @classroom.get('ownerID') # May be viewing page as admin
    courseID = @$('.bulk-course-select').val()
    selectedIDs = @getSelectedStudentIDs()
    nobodySelected = selectedIDs.length is 0
    @state.set errors: { nobodySelected }
    return if nobodySelected
    @removeCourse courseID, selectedIDs
    window.tracker?.trackEvent 'Teachers Class Students Remove-Course Selected', category: 'Teachers', classroomID: @classroom.id, courseID: courseID, ['Mixpanel']

  assignCourse: (courseID, members) ->
    return unless me.id is @classroom.get('ownerID') # May be viewing page as admin
    courseInstance = null
    numberEnrolled = 0
    remainingSpots = 0

    return Promise.resolve()
    # Find or make the necessary course instances
    .then =>
      courseInstance = @courseInstances.findWhere({ courseID, classroomID: @classroom.id })
      if not courseInstance
        courseInstance = new CourseInstance {
          courseID,
          classroomID: @classroom.id
          ownerID: @classroom.get('ownerID')
          aceConfig: {}
        }
        courseInstance.notyErrors = false # handling manually
        @courseInstances.add(courseInstance)
        return courseInstance.save()

    # Automatically apply licenses to students if necessary
    .then =>
      # Find the prepaids and users we're acting on (for both starter and full license cases)
      availablePrepaids = @prepaids.filter((prepaid) -> prepaid.status() is 'available' and prepaid.includesCourse(courseID))
      unenrolledStudents = _(members)
        .map((userID) => @students.get(userID))
        .filter((user) => not user.isEnrolled() or not user.prepaidIncludesCourse(courseID))
        .value()
      totalSpotsAvailable = _.reduce(prepaid.openSpots() for prepaid in availablePrepaids, (val, total) -> val + total) or 0

      canAssignCourses = totalSpotsAvailable >= _.size(unenrolledStudents)
      if not canAssignCourses
        # These ones just matter for display
        availableFullLicenses = @prepaids.filter((prepaid) -> prepaid.status() is 'available' and prepaid.get('type') is 'course')
        numStudentsWithoutFullLicenses = _(members)
          .map((userID) => @students.get(userID))
          .filter((user) => user.prepaidType() isnt 'course' or not user.isEnrolled())
          .size()
        numFullLicensesAvailable = _.reduce(prepaid.openSpots() for prepaid in availableFullLicenses, (val, total) -> val + total) or 0
        modal = new CoursesNotAssignedModal({
          selected: members.length
          numStudentsWithoutFullLicenses
          numFullLicensesAvailable
          courseID
        })
        @openModalView(modal)
        error = new Error('Not enough licenses available')
        error.handled = true
        throw error

      numberEnrolled = _.size(unenrolledStudents)
      remainingSpots = totalSpotsAvailable - numberEnrolled

      requests = []

      for prepaid in availablePrepaids when Math.min(_.size(unenrolledStudents), prepaid.openSpots()) > 0
        for i in [0...Math.min(_.size(unenrolledStudents), prepaid.openSpots())]
          user = unenrolledStudents.shift()
          requests.push(prepaid.redeem(user))

      @trigger 'begin-redeem-for-assign-course'
      return $.when(requests...)

    # Add the students to the course instances
    .then =>
      # refresh prepaids, since the racing multiple parallel redeem requests in the previous `then` probably did not
      # end up returning the final result of all those requests together.
      @prepaids.fetchByCreator(me.id)
      @fetchStudents()

      @trigger 'begin-assign-course' # Only used for test automation
      if members.length
        noty text: $.i18n.t('teacher.assigning_course'), layout: 'center', type: 'information', killer: true
        return courseInstance.addMembers(members)

    # Show a success/error notification
    .then =>
      course = @courses.get(courseID)
      lines = [
        $.i18n.t('teacher.assigned_msg_1')
          .replace('{{numberAssigned}}', members.length)
          .replace('{{courseName}}', course.get('name'))
      ]
      if numberEnrolled > 0
        lines.push(
          $.i18n.t('teacher.assigned_msg_2')
            .replace('{{numberEnrolled}}', numberEnrolled)
        )
        lines.push(
          $.i18n.t('teacher.assigned_msg_3')
          .replace('{{remainingSpots}}', remainingSpots)
        )
      noty text: lines.join('<br />'), layout: 'center', type: 'information', killer: true, timeout: 5000

      # TODO: refresh existing student progress. student may have progress from outside current classroom, and the course may have been updated upon assignment
      @calculateProgressAndLevels()
      @classroom.fetch()

    .catch (e) =>
      # TODO: Use this handling for errors site-wide?
      return if e.handled
      throw e if e instanceof Error and not application.isProduction()
      text = if e instanceof Error then 'Runtime error' else e.responseJSON?.message or e.message or $.i18n.t('loading_error.unknown')
      noty { text, layout: 'center', type: 'error', killer: true, timeout: 5000 }

  removeCourse: (courseID, members) ->
    return unless me.id is @classroom.get('ownerID') # May be viewing page as admin
    courseInstance = null
    membersBefore = 0

    return Promise.resolve()
    # Find the necessary course instance
    .then =>
      courseInstance = @courseInstances.findWhere({ courseID, classroomID: @classroom.id })
      if courseInstance
        membersBefore = courseInstance.get('members').length
      # if not courseInstance
      # TODO: show some message if no courseInstance?
      return courseInstance

    # Remove the students from the course instance
    .then =>
      @fetchStudents()

      @trigger 'begin-remove-course' # Only used for test automation
      if members.length
        noty text: $.i18n.t('teacher.removing_course'), layout: 'center', type: 'information', killer: true
        return courseInstance?.removeMembers(members)

    # Show a success/error notification
    .then (res) =>
      membersAfter = courseInstance?.get('members').length or 0
      numberRemoved = membersBefore - membersAfter
      course = @courses.get(courseID)
      lines = [
        $.i18n.t('teacher.removed_course_msg')
          .replace('{{numberRemoved}}', numberRemoved)
          .replace('{{courseName}}', course.get('name'))
      ]
      noty text: lines.join('<br />'), layout: 'center', type: 'information', killer: true, timeout: 5000

      @calculateProgressAndLevels()
      @classroom.fetch()

  onClickRevokeStudentButton: (e) ->
    button = $(e.currentTarget)
    userID = button.data('user-id')
    user = @students.get(userID)
    s = $.i18n.t('teacher.revoke_confirm').replace('{{student_name}}', user.broadName())
    return unless confirm(s)
    prepaid = user.makeCoursePrepaid()
    button.text($.i18n.t('teacher.revoking'))
    prepaid.revoke(user, {
      success: =>
        user.unset('coursePrepaid')
      error: (prepaid, jqxhr) =>
        msg = jqxhr.responseJSON.message
        noty text: msg, layout: 'center', type: 'error', killer: true, timeout: 3000
      complete: => @debouncedRender()
    })

  onClickRevokeAllStudentsButton: ->
    s = $.i18n.t('teacher.revoke_all_confirm')
    return unless confirm(s)
    for student in @students.models
      status = student.prepaidStatus()
      if status is 'enrolled' and student.prepaidType() is 'course'
        prepaid = student.makeCoursePrepaid()
        prepaid.revoke(student, {
          # The for loop completes before the success callback for the first student executes.
          # So, the `student` will be the last student when the callback executes.
          # Therefore, using a self calling anonymous function for the success callback
          # to retain the student data for each iteration.
          # Reference: https://www.pluralsight.com/guides/javascript-callbacks-variable-scope-problem
          success: (() ->
            st = student
            return -> st.unset('coursePrepaid')
          )()
          error: (prepaid, jqxhr) =>
            msg = jqxhr.responseJSON.message
            noty text: msg, layout: 'center', type: 'error', killer: true, timeout: 3000
          complete: => @debouncedRender()
        })

  onClickSelectAll: (e) ->
    e.preventDefault()
    checkboxStates = _.clone @state.get('checkboxStates')
    if _.all(checkboxStates)
      for studentID of checkboxStates
        checkboxStates[studentID] = false
    else
      for studentID of checkboxStates
        checkboxStates[studentID] = true
    @state.set { checkboxStates }

  onClickStudentCheckbox: (e) ->
    e.preventDefault()
    checkbox = $(e.currentTarget).find('input')
    studentID = checkbox.data('student-id')
    checkboxStates = _.clone @state.get('checkboxStates')
    checkboxStates[studentID] = not checkboxStates[studentID]
    @state.set { checkboxStates }

  onClickStudentProgressDot: (e) ->
    classroomId = @classroom.id
    courseId = @$(e.currentTarget).data('course-id')
    studentId = @$(e.currentTarget).data('student-id')
    levelSlug = @$(e.currentTarget).data('level-slug')
    levelProgress = @$(e.currentTarget).data('level-progress')
    window.tracker?.trackEvent 'Click Class Courses Tab Student Progress Dot', {category: 'Teachers', classroomId, courseId, studentId, levelSlug, levelProgress}

  calculateClassStats: ->
    return {} unless @classroom.sessions?.loaded and @students.loaded
    stats = {}

    playtime = 0
    total = 0
    for session in @classroom.sessions.models
      pt = session.get('playtime') or 0
      playtime += pt
      total += 1
    stats.averagePlaytime = if playtime and total then moment.duration(playtime / total, "seconds").humanize() else 0
    stats.totalPlaytime = if playtime then moment.duration(playtime, "seconds").humanize() else 0
    # TODO: Humanize differently ('1 hour' instead of 'an hour')

    levelIncludeMap = {}
    language = @classroom.get('aceConfig')?.language
    for level in @levels.models
      levelIncludeMap[level.get('original')] = not level.get('practice') and (not language? or level.get('primerLanguage') isnt language)
    completeSessions = @classroom.sessions.filter (s) -> s.get('state')?.complete and levelIncludeMap[s.get('level')?.original]
    stats.averageLevelsComplete = if @students.size() then (_.size(completeSessions) / @students.size()).toFixed(1) else 'N/A'  # '
    stats.totalLevelsComplete = _.size(completeSessions)

    enrolledUsers = @students.filter (user) -> user.isEnrolled()
    stats.enrolledUsers = _.size(enrolledUsers)

    return stats

  studentStatusString: (student) ->
    status = student.prepaidStatus()
    expires = student.get('coursePrepaid')?.endDate
    date = if expires? then moment(expires).utc().format('ll') else ''
    utils.formatStudentLicenseStatusDate(status, date)

  getTopScore: ({level, session}) ->
    return unless level and session
    scoreType = _.first(level.get('scoreTypes'))
    if _.isObject(scoreType)
      scoreType = scoreType.type
    topScores = LevelSession.getTopScores({level: level.toJSON(), session: session.toJSON()})
    topScore = _.find(topScores, {type: scoreType})
    return topScore

  shouldShowGoogleClassroomButton: ->
    me.useGoogleClassroom() && @classroom.isGoogleClassroom()

  onClickSyncGoogleClassroom: (e) ->
    $('.sync-google-classroom-btn').text("Syncing...")
    $('.sync-google-classroom-btn').attr('disabled', true)
    application.gplusHandler.loadAPI({
      success: =>
        application.gplusHandler.connect({
          scope: GoogleClassroomHandler.scopes
          success: =>
            @syncGoogleClassroom()
          error: =>
            $('.sync-google-classroom-btn').text($.i18n.t('teacher.sync_google_classroom'))
            $('.sync-google-classroom-btn').attr('disabled', false)
        })
    })

  syncGoogleClassroom: ->
    GoogleClassroomHandler.importStudentsToClassroom(@classroom)
    .then (importedMembers) =>
      if importedMembers.length > 0
        console.debug("Students imported to classroom:", importedMembers)

        if @students.length == 0
          @students = new Users(importedMembers)
          @state.set('students', @students)
        for course in @courses.models
          continue if not course.get('free')
          courseInstance = @courseInstances.findWhere({classroomID: @classroom.get("_id"), courseID: course.id})
          if courseInstance
            importedMembers.forEach((i) => courseInstance.get("members").push(i._id))
        @fetchStudents()
    , (err) =>
      noty text: err or 'Error in importing students.', layout: 'topCenter', timeout: 3000, type: 'error'
    .then () =>
      $('.sync-google-classroom-btn').text($.i18n.t('teacher.sync_google_classroom'))
      $('.sync-google-classroom-btn').attr('disabled', false)
