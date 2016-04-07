RootView = require 'views/core/RootView'
template = require 'templates/courses/teacher-class-view'
helper = require 'lib/coursesHelper'
ClassroomSettingsModal = require 'views/courses/ClassroomSettingsModal'
InviteToClassroomModal = require 'views/courses/InviteToClassroomModal'
ActivateLicensesModal = require 'views/courses/ActivateLicensesModal'
RemoveStudentModal = require 'views/courses/RemoveStudentModal'

Classroom = require 'models/Classroom'
Classrooms = require 'collections/Classrooms'
LevelSessions = require 'collections/LevelSessions'
User = require 'models/User'
Users = require 'collections/Users'
Courses = require 'collections/Courses'
CourseInstance = require 'models/CourseInstance'
CourseInstances = require 'collections/CourseInstances'
Campaigns = require 'collections/Campaigns'

module.exports = class TeacherClassView extends RootView
  id: 'teacher-class-view'
  template: template
  
  events:
    'click .edit-classroom': 'onClickEditClassroom'
    'click .add-students-btn': 'onClickAddStudents'
    'click .sort-by-name': 'sortByName'
    'click .sort-by-progress': 'sortByProgress'
    'click #copy-url-btn': 'copyURL'
    'click #copy-code-btn': 'copyCode'
    'click .remove-student-link': 'onClickRemoveStudentLink'
    'click .enroll-student-button': 'onClickEnroll'
    'click .assign-to-selected-students': 'onClickBulkAssign'
    'click .enroll-selected-students': 'onClickBulkEnroll'
    'click .select-all': 'onClickSelectAll'
    'click .student-checkbox': 'onClickStudentCheckbox'
    'change .course-select': 'onChangeCourseSelect'

  initialize: (options, classroomID) ->
    super(options)
    @progressDotTemplate = require 'templates/courses/progress-dot'
    
    @sortAttribute = 'name'
    @sortDirection = 1
    
    @classroom = new Classroom({ _id: classroomID })
    @classroom.fetch()
    @supermodel.trackModel(@classroom)
    
    @listenTo @classroom, 'sync', ->
      @students = new Users()
      jqxhrs = @students.fetchForClassroom(@classroom, removeDeleted: true)
      if jqxhrs.length > 0
        @supermodel.trackCollection(@students)
      @listenTo @students, 'sync', @sortByName
      @listenTo @students, 'sort', @renderSelectors.bind(@, '.students-table', '.student-levels-table')
      
      @classroom.sessions = new LevelSessions()
      requests = @classroom.sessions.fetchForAllClassroomMembers(@classroom)
      @supermodel.trackRequests(requests)
      
    @courses = new Courses()
    @courses.fetch()
    @supermodel.trackCollection(@courses)
    
    @campaigns = new Campaigns()
    @campaigns.fetchByType('course')
    @supermodel.trackCollection(@campaigns)
    
    @courseInstances = new CourseInstances()
    @courseInstances.fetchByOwner(me.id)
    @supermodel.trackCollection(@courseInstances)

  onLoaded: ->
    @removeDeletedStudents()
    
    @classCode = @classroom.get('codeCamel') or @classroom.get('code')
    @joinURL = document.location.origin + "/courses?_cc=" + @classCode
    
    @earliestIncompleteLevel = helper.calculateEarliestIncomplete(@classroom, @courses, @campaigns, @courseInstances, @students)
    @latestCompleteLevel = helper.calculateLatestComplete(@classroom, @courses, @campaigns, @courseInstances, @students)
    for student in @students.models
      # TODO: this is a weird hack
      studentsStub = new Users([ student ])
      student.latestCompleteLevel = helper.calculateLatestComplete(@classroom, @courses, @campaigns, @courseInstances, studentsStub)
      
    classroomsStub = new Classrooms([ @classroom ])
    @progressData = helper.calculateAllProgress(classroomsStub, @courses, @campaigns, @courseInstances, @students)
    # @conceptData = helper.calculateConceptsCovered(classroomsStub, @courses, @campaigns, @courseInstances, @students)
    
    @selectedCourse = @courses.first()
    super()
    
  copyCode: ->
    @$('#join-code-input').val(@classCode).select()
    @tryCopy()
  
  copyURL: ->
    @$('#join-url-input').val(@joinURL).select()
    @tryCopy()
    
  tryCopy: ->
    try
      document.execCommand('copy')
      application.tracker?.trackEvent 'Classroom copy URL', category: 'Courses', classroomID: @classroom.id, url: @joinURL
    catch err
      message = 'Oops, unable to copy'
      noty text: message, layout: 'topCenter', type: 'error', killer: false
    
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
    @render()
    application.tracker?.trackEvent 'Classroom removed student', category: 'Courses', classroomID: @classroom.id, userID: e.user.id

  onClickAddStudents: (e) =>
    modal = new InviteToClassroomModal({ classroom: @classroom })
    @openModalView(modal)
    @listenToOnce modal, 'hide', @render
  
  removeDeletedStudents: () ->
    _.remove(@classroom.get('members'), (memberID) =>
      not @students.get(memberID) or @students.get(memberID)?.get('deleted')
    )
    true
    
  sortByName: (e) ->
    if @sortValue is 'name'
      @sortDirection = -@sortDirection
    else
      @sortValue = 'name'
      @sortDirection = 1
      
    dir = @sortDirection
    @students.comparator = (student1, student2) ->
      return (if student1.broadName().toLowerCase() < student2.broadName().toLowerCase() then -dir else dir)
    @students.sort()
    
  sortByProgress: (e) ->
    if @sortValue is 'progress'
      @sortDirection = -@sortDirection
    else
      @sortValue = 'progress'
      @sortDirection = 1
      
    dir = @sortDirection
    
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
    modal = new ActivateLicensesModal { @classroom, selectedUsers, users: @students }
    @openModalView(modal)
    modal.once 'redeem-users', -> document.location.reload()
    application.tracker?.trackEvent 'Classroom started enroll students', category: 'Courses'
  
  onClickBulkEnroll: ->
    courseID = @$('.bulk-course-select').val()
    courseInstance = @courseInstances.findWhere({ courseID, classroomID: @classroom.id })
    userIDs = @getSelectedStudentIDs().toArray()
    selectedUsers = new Users(@students.get(userID) for userID in userIDs)
    modal = new ActivateLicensesModal { @classroom, selectedUsers, users: @students }
    @openModalView(modal)
    modal.once 'redeem-users', -> document.location.reload()
    application.tracker?.trackEvent 'Classroom started enroll students', category: 'Courses'
    
  onClickBulkAssign: ->
    courseID = @$('.bulk-course-select').val()
    courseInstance = @courseInstances.findWhere({ courseID, classroomID: @classroom.id })
    selectedIDs = @getSelectedStudentIDs()
    members = selectedIDs.filter((index, userID) =>
      user = @students.get(userID)
      user.isEnrolled()
    ).toArray()
    
    @assigningToUnenrolled = _.any selectedIDs, (userID) =>
      not @students.get(userID).isEnrolled()
    
    @$('.cant-assign-to-unenrolled').toggleClass('visible', @assigningToUnenrolled)
    
    @assigningToNobody = selectedIDs.length is 0
    @$('.no-students-selected').toggleClass('visible', @assigningToNobody)

    if courseInstance
      courseInstance.addMembers members, {
        success: @onBulkAssignSuccess
      }
    else
      courseInstance = new CourseInstance {
        courseID,
        classroomID: @classroom.id
        ownerID: @classroom.get('ownerID')
        aceConfig: {}
      }
      @courseInstances.add(courseInstance)
      courseInstance.save {}, {
        success: =>
          courseInstance.addMembers members, {
            success: @onBulkAssignSuccess
          }
      }
    null
    
  onBulkAssignSuccess: =>
    @render() unless @destroyed
    noty text: $.i18n.t('teacher.assigned'), layout: 'center', type: 'information', killer: true, timeout: 5000
    
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
  
  onChangeCourseSelect: (e) ->
    @selectedCourse = @courses.get($(e.currentTarget).val())
    @renderSelectors('.render-on-course-sync')

  classStats: ->
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
