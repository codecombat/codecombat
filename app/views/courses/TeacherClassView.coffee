RootView = require 'views/core/RootView'
State = require 'models/State'
template = require 'templates/courses/teacher-class-view'
helper = require 'lib/coursesHelper'
ClassroomSettingsModal = require 'views/courses/ClassroomSettingsModal'
InviteToClassroomModal = require 'views/courses/InviteToClassroomModal'
ActivateLicensesModal = require 'views/courses/ActivateLicensesModal'
EditStudentModal = require 'views/teachers/EditStudentModal'
RemoveStudentModal = require 'views/courses/RemoveStudentModal'

Campaigns = require 'collections/Campaigns'
Classroom = require 'models/Classroom'
Classrooms = require 'collections/Classrooms'
Levels = require 'collections/Levels'
LevelSessions = require 'collections/LevelSessions'
User = require 'models/User'
Users = require 'collections/Users'
Course = require 'models/Course'
Courses = require 'collections/Courses'
CourseInstance = require 'models/CourseInstance'
CourseInstances = require 'collections/CourseInstances'

module.exports = class TeacherClassView extends RootView
  id: 'teacher-class-view'
  template: template

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
    'click .assign-to-selected-students': 'onClickBulkAssign'
    'click .enroll-selected-students': 'onClickBulkEnroll'
    'click .export-student-progress-btn': 'onClickExportStudentProgress'
    'click .select-all': 'onClickSelectAll'
    'click .student-checkbox': 'onClickStudentCheckbox'
    'keyup #student-search': 'onKeyPressStudentSearch'
    'change .course-select, .bulk-course-select': 'onChangeCourseSelect'
      
  getInitialState: ->
    {
      sortAttribute: 'name'
      sortDirection: 1
      activeTab: '#' + (Backbone.history.getHash() or 'students-tab')
      students: new Users()
      classCode: ""
      joinURL: ""
      errors:
        assigningToNobody: false
        assigningToUnenrolled: false
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
    @singleStudentCourseProgressDotTemplate = require 'templates/teachers/hovers/progress-dot-single-student-course'
    @singleStudentLevelProgressDotTemplate = require 'templates/teachers/hovers/progress-dot-single-student-level'
    @allStudentsLevelProgressDotTemplate = require 'templates/teachers/hovers/progress-dot-all-students-single-level'
    
    @debouncedRender = _.debounce @render
    
    @state = new State(@getInitialState())
    @updateHash @state.get('activeTab') # TODO: Don't push to URL history (maybe don't use url fragment for default tab)
    
    @classroom = new Classroom({ _id: classroomID })
    @supermodel.trackRequest @classroom.fetch()
    @onKeyPressStudentSearch = _.debounce(@onKeyPressStudentSearch, 200)
    
    @students = new Users()
    @listenTo @classroom, 'sync', ->
      jqxhrs = @students.fetchForClassroom(@classroom, removeDeleted: true)
      @supermodel.trackRequests jqxhrs
      
      @classroom.sessions = new LevelSessions()
      requests = @classroom.sessions.fetchForAllClassroomMembers(@classroom)
      @supermodel.trackRequests(requests)

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
    @supermodel.trackRequest @levels.fetchForClassroom(classroomID, {data: {project: 'original,concepts,practice'}})
    
    @attachMediatorEvents()
    window.tracker?.trackEvent 'Teachers Class Loaded', category: 'Teachers', classroomID: @classroom.id, ['Mixpanel']

  attachMediatorEvents: () ->
    # Model/Collection events
    @listenTo @classroom, 'sync change update', ->
      classCode = @classroom.get('codeCamel') or @classroom.get('code')
      @state.set {
        classCode: classCode
        joinURL: document.location.origin + "/courses?_cc=" + classCode
      }
    @listenTo @courses, 'sync change update', ->
      @setCourseMembers() # Is this necessary?
      @state.set selectedCourse: @courses.first() unless @state.get('selectedCourse')
    @listenTo @courseInstances, 'sync change update', ->
      @setCourseMembers()
    @listenTo @courseInstances, 'add-members', ->
      noty text: $.i18n.t('teacher.assigned'), layout: 'center', type: 'information', killer: true, timeout: 5000
    @listenTo @students, 'sync change update add remove reset', ->
      # Set state/props of things that depend on students?
      # Set specific parts of state based on the models, rather than just dumping the collection there?
      @calculateProgressAndLevels()
      classStats = @calculateClassStats()
      @state.set classStats: classStats if classStats
      @state.set students: @students
      checkboxStates = {}
      for student in @students.models
        checkboxStates[student.id] = @state.get('checkboxStates')[student.id] or false
      @state.set { checkboxStates }
    @listenTo @students, 'sort', ->
      @state.set students: @students
    @listenTo @, 'course-select:change', ({ selectedCourse }) ->
      @state.set selectedCourse: selectedCourse

  setCourseMembers: =>
    for course in @courses.models
      course.instance = @courseInstances.findWhere({ courseID: course.id, classroomID: @classroom.id })
      course.members = course.instance?.get('members') or []
    null
    
  onLoaded: ->
    @removeDeletedStudents() # TODO: Move this to mediator listeners? For both classroom and students?
    @calculateProgressAndLevels()
    
    # render callback setup
    @listenTo @courseInstances, 'sync change update', @debouncedRender
    @listenTo @state, 'sync change', ->
      if _.isEmpty(_.omit(@state.changed, 'searchTerm'))
        @renderSelectors('#enrollment-status-table')
      else
        @debouncedRender()
    @listenTo @students, 'sort', @debouncedRender
    super()
  
  afterRender: ->
    super(arguments...)
    $('.progress-dot').each (i, el) ->
      dot = $(el)
      dot.tooltip({
        html: true
        container: dot
      }).delegate '.tooltip', 'mousemove', ->
        dot.tooltip('hide')
    
  calculateProgressAndLevels: ->
    return unless @supermodel.progress is 1
    # TODO: How to structure this in @state?
    for student in @students.models
      # TODO: this is a weird hack
      studentsStub = new Users([ student ])
      student.latestCompleteLevel = helper.calculateLatestComplete(@classroom, @courses, @courseInstances, studentsStub)
    
    earliestIncompleteLevel = helper.calculateEarliestIncomplete(@classroom, @courses, @courseInstances, @students)
    latestCompleteLevel = helper.calculateLatestComplete(@classroom, @courses, @courseInstances, @students)
      
    classroomsStub = new Classrooms([ @classroom ])
    progressData = helper.calculateAllProgress(classroomsStub, @courses, @courseInstances, @students)
    # conceptData: helper.calculateConceptsCovered(classroomsStub, @courses, @campaigns, @courseInstances, @students)
    
    @state.set {
      earliestIncompleteLevel
      latestCompleteLevel
      progressData
      classStats: @calculateClassStats()
    }

  onClickNavTabLink: (e) ->
    e.preventDefault()
    hash = $(e.target).closest('a').attr('href')
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

  tryCopy: ->
    try
      document.execCommand('copy')
    catch err
      message = 'Oops, unable to copy'
      noty text: message, layout: 'topCenter', type: 'error', killer: false
  
  onClickUnarchive: ->
    window.tracker?.trackEvent 'Teachers Class Unarchive', category: 'Teachers', classroomID: @classroom.id, ['Mixpanel']
    @classroom.save { archived: false }
  
  onClickEditClassroom: (e) ->
    window.tracker?.trackEvent 'Teachers Class Edit Class Started', category: 'Teachers', classroomID: @classroom.id, ['Mixpanel']
    classroom = @classroom
    modal = new ClassroomSettingsModal({ classroom: classroom })
    @openModalView(modal)
    @listenToOnce modal, 'hide', @render

  onClickEditStudentLink: (e) ->
    window.tracker?.trackEvent 'Teachers Class Students Edit', category: 'Teachers', classroomID: @classroom.id, ['Mixpanel']
    user = @students.get($(e.currentTarget).data('student-id'))
    modal = new EditStudentModal({ user, @classroom })
    @openModalView(modal)

  onClickRemoveStudentLink: (e) ->
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
    window.tracker?.trackEvent 'Teachers Class Add Students', category: 'Teachers', classroomID: @classroom.id, ['Mixpanel']
    modal = new InviteToClassroomModal({ classroom: @classroom })
    @openModalView(modal)
    @listenToOnce modal, 'hide', @render

  removeDeletedStudents: () ->
    return unless @classroom.loaded and @students.loaded
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
    userID = $(e.currentTarget).data('user-id')
    user = @students.get(userID)
    selectedUsers = new Users([user])
    @enrollStudents(selectedUsers)
    window.tracker?.trackEvent $(e.currentTarget).data('event-action'), category: 'Teachers', classroomID: @classroom.id, userID: userID, ['Mixpanel']

  onClickBulkEnroll: ->
    userIDs = @getSelectedStudentIDs()
    selectedUsers = new Users(@students.get(userID) for userID in userIDs)
    @enrollStudents(selectedUsers)
    window.tracker?.trackEvent 'Teachers Class Students Enroll Selected', category: 'Teachers', classroomID: @classroom.id, ['Mixpanel']

  enrollStudents: (selectedUsers) ->
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
    courseOrder = []
    for course, index in @classroom.get('courses')
      courseLabels += "CS#{index + 1} Playtime,"
      courseOrder.push(course._id)
    csvContent = "data:text/csv;charset=utf-8,Username,Email,Total Playtime,#{courseLabels}Concepts\n"
    levelCourseMap = {}
    for trimCourse in @classroom.get('courses')
      for trimLevel in trimCourse.levels
        levelCourseMap[trimLevel.original] = @courses.get(trimCourse._id)
    for student in @students.models
      concepts = []
      for trimCourse in @classroom.get('courses')
        course = @courses.get(trimCourse._id)
        instance = @courseInstances.findWhere({ courseID: course.id, classroomID: @classroom.id })
        if instance and instance.hasMember(student)
          for trimLevel in trimCourse.levels
            level = @levels.findWhere({ original: trimLevel.original })
            progress = @state.get('progressData').get({ classroom: @classroom, course: course, level: level, user: student })
            concepts.push(level.get('concepts') ? []) if progress?.completed
      concepts = _.union(_.flatten(concepts))
      conceptsString = _.map(concepts, (c) -> $.i18n.t("concepts." + c)).join(', ')
      coursePlaytimeMap = {}
      playtime = 0
      for session in @classroom.sessions.models when session.get('creator') is student.id
        playtime += session.get('playtime') or 0
        if courseID = levelCourseMap[session.get('level')?.original]?.id
          coursePlaytimeMap[courseID] ?= 0
          coursePlaytimeMap[courseID] += session.get('playtime') or 0
      playtimeString = if playtime is 0 then "0" else moment.duration(playtime, 'seconds').humanize()
      for course in @courses.models
        coursePlaytimeMap[course.id] ?= 0
      coursePlaytimes = []
      for courseID, playtime of coursePlaytimeMap
        coursePlaytimes.push
          courseID: courseID
          playtime: playtime
      coursePlaytimes.sort (a, b) ->
        return -1 if courseOrder.indexOf(a.courseID) < courseOrder.indexOf(b.courseID)
        return 0 if courseOrder.indexOf(a.courseID) is courseOrder.indexOf(b.courseID)
        return 1
      coursePlaytimesString = ""
      for coursePlaytime, index in coursePlaytimes
        if coursePlaytime.playtime is 0
          coursePlaytimesString += "0,"
        else
          coursePlaytimesString += "#{moment.duration(coursePlaytime.playtime, 'seconds').humanize()},"
      csvContent += "#{student.get('name')},#{student.get('email')},#{playtimeString},#{coursePlaytimesString}\"#{conceptsString}\"\n"
    csvContent = csvContent.substring(0, csvContent.length - 1)
    encodedUri = encodeURI(csvContent)
    window.open(encodedUri)

  onClickAssignStudentButton: (e) ->
    userID = $(e.currentTarget).data('user-id')
    user = @students.get(userID)
    members = [userID]
    courseID = $(e.currentTarget).data('course-id')
    @assignCourse courseID, members
    window.tracker?.trackEvent 'Teachers Class Students Assign Selected', category: 'Teachers', classroomID: @classroom.id, courseID: courseID, userID: userID, ['Mixpanel']

  onClickBulkAssign: ->
    courseID = @$('.bulk-course-select').val()
    selectedIDs = @getSelectedStudentIDs()
    members = selectedIDs.filter (userID) =>
      user = @students.get(userID)
      user.isEnrolled()
    assigningToUnenrolled = _.any selectedIDs, (userID) =>
      not @students.get(userID).isEnrolled()
    assigningToNobody = selectedIDs.length is 0
    @state.set errors: { assigningToNobody, assigningToUnenrolled }
    @assignCourse courseID, members
    window.tracker?.trackEvent 'Teachers Class Students Assign Selected', category: 'Teachers', classroomID: @classroom.id, courseID: courseID, ['Mixpanel']

  # TODO: Move this to the model. Use promises/callbacks?
  assignCourse: (courseID, members) ->
    courseInstance = @courseInstances.findWhere({ courseID, classroomID: @classroom.id })
    if courseInstance
      courseInstance.addMembers members
    else
      courseInstance = new CourseInstance {
        courseID,
        classroomID: @classroom.id
        ownerID: @classroom.get('ownerID')
        aceConfig: {}
      }
      @courseInstances.add(courseInstance)
      courseInstance.save {}, {
        success: ->
          courseInstance.addMembers members
      }
    null

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

    levelPracticeMap = {}
    levelPracticeMap[level.id] = level.get('practice') ? false for level in @levels.models
    completeSessions = @classroom.sessions.filter (s) -> s.get('state')?.complete and not levelPracticeMap[s.get('levelID')]
    stats.averageLevelsComplete = if @students.size() then (_.size(completeSessions) / @students.size()).toFixed(1) else 'N/A'  # '
    stats.totalLevelsComplete = _.size(completeSessions)

    enrolledUsers = @students.filter (user) -> user.isEnrolled()
    stats.enrolledUsers = _.size(enrolledUsers)
    
    return stats

  studentStatusString: (student) ->
    status = student.prepaidStatus()
    expires = student.get('coursePrepaid')?.endDate
    string = switch status
      when 'not-enrolled' then $.i18n.t('teacher.status_not_enrolled')
      when 'enrolled' then (if expires then $.i18n.t('teacher.status_enrolled') else '-')
      when 'expired' then $.i18n.t('teacher.status_expired')
    return string.replace('{{date}}', moment(expires).utc().format('l'))
