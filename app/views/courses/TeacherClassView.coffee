RootView = require 'views/core/RootView'
State = require 'models/State'
template = require 'templates/courses/teacher-class-view'
helper = require 'lib/coursesHelper'
ClassroomSettingsModal = require 'views/courses/ClassroomSettingsModal'
InviteToClassroomModal = require 'views/courses/InviteToClassroomModal'
ActivateLicensesModal = require 'views/courses/ActivateLicensesModal'
RemoveStudentModal = require 'views/courses/RemoveStudentModal'

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
    'click .students-tab-btn': (e) ->
      e.preventDefault()
      @trigger 'open-students-tab'
    'click .course-progress-tab-btn': (e) ->
      e.preventDefault()
      @trigger 'open-course-progress-tab'
    'click .unarchive-btn': 'onClickUnarchive'
    'click .edit-classroom': 'onClickEditClassroom'
    'click .add-students-btn': 'onClickAddStudents'
    'click .sort-by-name': 'sortByName'
    'click .sort-by-progress': 'sortByProgress'
    'click #copy-url-btn': 'copyURL'
    'click #copy-code-btn': 'copyCode'
    'click .remove-student-link': 'onClickRemoveStudentLink'
    'click .assign-student-button': 'onClickAssign'
    'click .enroll-student-button': 'onClickEnroll'
    'click .assign-to-selected-students': 'onClickBulkAssign'
    'click .enroll-selected-students': 'onClickBulkEnroll'
    'click .export-student-progress-btn': 'onClickExportStudentProgress'
    'click .select-all': 'onClickSelectAll'
    'click .student-checkbox': 'onClickStudentCheckbox'
    'change .course-select, .bulk-course-select': (e) ->
      @trigger 'course-select:change', { selectedCourse: @courses.get($(e.currentTarget).val()) }
      
  getInitialState: ->
    if Backbone.history.getHash() in ['students-tab', 'course-progress-tab']
      activeTab = '#' + Backbone.history.getHash()
    else
      activeTab = '#students-tab'
    {
      sortAttribute: 'name'
      sortDirection: 1
      activeTab
      students: new Users()
      classCode: ""
      joinURL: ""
      errors:
        assigningToNobody: false
        assigningToUnenrolled: false
      selectedCourse: undefined
      classStats:
        averagePlaytime: ""
        totalPlaytime: ""
        averageLevelsComplete: ""
        totalLevelsComplete: ""
        enrolledUsers: ""
    }

  initialize: (options, classroomID) ->
    super(options)
    @singleStudentCourseProgressDotTemplate = require 'templates/teachers/hovers/progress-dot-single-student-course'
    @singleStudentLevelProgressDotTemplate = require 'templates/teachers/hovers/progress-dot-single-student-level'
    @allStudentsLevelProgressDotTemplate = require 'templates/teachers/hovers/progress-dot-all-students-single-level'
    
    @state = new State(@getInitialState())
    window.location.hash = @state.get('activeTab') # TODO: Don't push to URL history (maybe don't use url fragment for default tab)
    
    @classroom = new Classroom({ _id: classroomID })
    @classroom.fetch()
    @supermodel.trackModel(@classroom)
    
    @students = new Users()
    @listenTo @classroom, 'sync', ->
      jqxhrs = @students.fetchForClassroom(@classroom, removeDeleted: true)
      if jqxhrs.length > 0
        @supermodel.trackCollection(@students)
      
      @classroom.sessions = new LevelSessions()
      requests = @classroom.sessions.fetchForAllClassroomMembers(@classroom)
      @supermodel.trackRequests(requests)

    @courses = new Courses()
    @courses.fetch()
    @supermodel.trackCollection(@courses)

    @courseInstances = new CourseInstances()
    @courseInstances.fetchForClassroom(classroomID)
    @supermodel.trackCollection(@courseInstances)
    
    @levels = new Levels()
    @levels.fetchForClassroom(classroomID, {data: {project: 'original,concepts'}})
    @supermodel.trackCollection(@levels)
    
    @attachMediatorEvents()
      
  attachMediatorEvents: () ->
    @listenTo @state, 'sync change', @render
    # Model/Collection events
    @listenTo @classroom, 'sync change update', ->
      @removeDeletedStudents()
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
      @render() # TODO: use state
    @listenTo @courseInstances, 'add-members', ->
      noty text: $.i18n.t('teacher.assigned'), layout: 'center', type: 'information', killer: true, timeout: 5000
    @listenToOnce @students, 'sync', # TODO: This seems like it's in the wrong place?
      @sortByName
    @listenTo @students, 'sync change update add remove reset', ->
      # Set state/props of things that depend on students?
      # Set specific parts of state based on the models, rather than just dumping the collection there?
      @removeDeletedStudents()
      @calculateProgressAndLevels()
      classStats = @calculateClassStats()
      @state.set classStats: classStats if classStats
      @state.set students: @students
    @listenTo @students, 'sort', ->
      @state.set students: @students
      @render()
    
    # DOM events
    @listenTo @, 'open-students-tab', ->
      if window.location.hash isnt '#students-tab'
        window.location.hash = '#students-tab'
      @state.set activeTab: '#students-tab'
    @listenTo @, 'open-course-progress-tab', ->
      if window.location.hash isnt '#course-progress-tab'
        window.location.hash = '#course-progress-tab'
      @state.set activeTab: '#course-progress-tab'
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
  
  copyCode: ->
    @$('#join-code-input').val(@state.get('classCode')).select()
    @tryCopy()

  copyURL: ->
    @$('#join-url-input').val(@state.get('joinURL')).select()
    @tryCopy()

  tryCopy: ->
    try
      document.execCommand('copy')
      application.tracker?.trackEvent 'Classroom copy URL', category: 'Courses', classroomID: @classroom.id, url: @state.joinURL
    catch err
      message = 'Oops, unable to copy'
      noty text: message, layout: 'topCenter', type: 'error', killer: false
  
  onClickUnarchive: ->
    @classroom.save { archived: false }
  
  onClickEditClassroom: (e) ->
    classroom = @classroom
    modal = new ClassroomSettingsModal({ classroom: classroom })
    @openModalView(modal)
    @listenToOnce modal, 'hide', @render

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
    application.tracker?.trackEvent 'Classroom removed student', category: 'Courses', classroomID: @classroom.id, userID: e.user.id

  onClickAddStudents: (e) =>
    modal = new InviteToClassroomModal({ classroom: @classroom })
    @openModalView(modal)
    @listenToOnce modal, 'hide', @render

  removeDeletedStudents: () ->
    return unless @classroom.loaded and @students.loaded
    _.remove(@classroom.get('members'), (memberID) =>
      not @students.get(memberID) or @students.get(memberID)?.get('deleted')
    )
    true

  sortByName: (e) ->
    if @state.get('sortValue') is 'name'
      @state.set('sortDirection', -@state.get('sortDirection'))
    else
      @state.set('sortValue', 'name')
      @state.set('sortDirection', 1)
      
    dir = @state.get('sortDirection')
    @students.comparator = (student1, student2) ->
      return (if student1.broadName().toLowerCase() < student2.broadName().toLowerCase() then -dir else dir)
    @students.sort()

  sortByProgress: (e) ->
    if @state.get('sortValue') is 'progress'
      @state.set('sortDirection', -@state.get('sortDirection'))
    else
      @state.set('sortValue', 'progress')
      @state.set('sortDirection', 1)
      
    dir = @state.get('sortDirection')
    
    @students.comparator = (student) ->
      #TODO: I would like for this to be in the Level model,
      #      but it doesn't know about its own courseNumber
      level = student.latestCompleteLevel
      if not level
        return -dir
      return dir * ((1000 * level.courseNumber) + level.levelNumber)
    @students.sort()

  getSelectedStudentIDs: ->
    @$('.student-row .checkbox-flat input:checked').map (index, checkbox) ->
      $(checkbox).data('student-id')

  ensureInstance: (courseID) ->

  onClickEnroll: (e) ->
    userID = $(e.currentTarget).data('user-id')
    user = @students.get(userID)
    selectedUsers = new Users([user])
    @enrollStudents(selectedUsers)
  
  onClickBulkEnroll: ->
    courseID = @$('.bulk-course-select').val()
    courseInstance = @courseInstances.findWhere({ courseID, classroomID: @classroom.id })
    userIDs = @getSelectedStudentIDs().toArray()
    selectedUsers = new Users(@students.get(userID) for userID in userIDs)
    @enrollStudents(selectedUsers)
    
  enrollStudents: (selectedUsers) ->
    modal = new ActivateLicensesModal { @classroom, selectedUsers, users: @students }
    @openModalView(modal)
    modal.once 'redeem-users', (enrolledUsers) =>
      enrolledUsers.each (newUser) =>
        user = @students.get(newUser.id)
        if user
          user.set(newUser.attributes)
      null
    application.tracker?.trackEvent 'Classroom started enroll students', category: 'Courses'

  onClickExportStudentProgress: ->
    # TODO: Does not yield .csv download on Safari, and instead opens a new tab with the .csv contents
    csvContent = "data:text/csv;charset=utf-8,Username, Email, Playtime, Concepts\n"
    for student in @students.models
      concepts = []
      for course, index in @courses.models
        instance = @courseInstances.findWhere({ courseID: course.id, classroomID: @classroom.id })
        if instance and instance.hasMember(student)
          # TODO: @levels collection is for the classroom, and not per-course
          for level, index in @levels.models
            progress = @state.get('progressData').get({ classroom: @classroom, course: course, level: level, user: student })
            concepts.push(level.get('concepts') ? []) if progress?.completed
      concepts = _.union(_.flatten(concepts))
      conceptsString = _.map(concepts, (c) -> $.i18n.t("concepts." + c)).join(', ')
      playtime = 0
      for session in @classroom.sessions.models when session.get('creator') is student.id
        playtime += session.get('playtime') or 0
      playtimeString = moment.duration(playtime, 'seconds').humanize()
      csvContent += "#{student.get('name')},#{student.get('email')},#{playtimeString},\"#{conceptsString}\"\n"
    csvContent = csvContent.substring(0, csvContent.length - 1)
    encodedUri = encodeURI(csvContent)
    window.open(encodedUri)

    
  onClickAssign: (e) ->
    userID = $(e.currentTarget).data('user-id')
    user = @students.get(userID)
    members = [userID]
    courseID = $(e.currentTarget).data('course-id')
    
    @assignCourse courseID, members
    
  onClickBulkAssign: ->
    courseID = @$('.bulk-course-select').val()
    selectedIDs = @getSelectedStudentIDs()
    members = selectedIDs.filter((index, userID) =>
      user = @students.get(userID)
      user.isEnrolled()
    ).toArray()
    
    assigningToUnenrolled = _.any selectedIDs, (userID) =>
      not @students.get(userID).isEnrolled()
      
    assigningToNobody = selectedIDs.length is 0
    
    @state.set errors: { assigningToNobody, assigningToUnenrolled }
    
    @assignCourse courseID, members
    
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
    checkboxes = @$('.student-checkbox input')
    if _.all(checkboxes, 'checked')
      @$('.select-all input').prop('checked', false)
      checkboxes.prop('checked', false)
    else
      @$('.select-all input').prop('checked', true)
      checkboxes.prop('checked', true)
    null

  onClickStudentCheckbox: (e) ->
    e.preventDefault()
    # $(e.target).$()
    checkbox = $(e.currentTarget).find('input')
    checkbox.prop('checked', not checkbox.prop('checked'))
    # checkboxes.prop('checked', false)
    checkboxes = @$('.student-checkbox input')
    @$('.select-all input').prop('checked', _.all(checkboxes, 'checked'))

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

    completeSessions = @classroom.sessions.filter (s) -> s.get('state')?.complete
    stats.averageLevelsComplete = if @students.size() then (_.size(completeSessions) / @students.size()).toFixed(1) else 'N/A'  # '
    stats.totalLevelsComplete = _.size(completeSessions)

    enrolledUsers = @students.filter (user) -> user.get('coursePrepaidID')
    stats.enrolledUsers = _.size(enrolledUsers)
    
    return stats
