RootView = require 'views/core/RootView'
template = require 'templates/courses/teacher-class-view'
helper = require 'lib/coursesHelper'
InviteToClassroomModal = require 'views/courses/InviteToClassroomModal'

Classroom = require 'models/Classroom'
Classrooms = require 'collections/Classrooms'
LevelSessions = require 'collections/LevelSessions'
Users = require 'collections/Users'
Courses = require 'collections/Courses'
CourseInstances = require 'collections/CourseInstances'
Campaigns = require 'collections/Campaigns'

module.exports = class TeacherClassView extends RootView
  id: 'teacher-class-view'
  template: template
  
  events:
    'click .add-students-button': 'onClickAddStudents'
    'click .enroll-student-button': 'onClickEnrollStudent'
    'click .sort-by-name': 'sortByName'
    'click .sort-by-progress': 'sortByProgress'
    'click #copy-url-btn': 'copyURL'
    'click #copy-code-btn': 'copyCode'
    'click .assign-to-selected-students': 'onClickBulkAssign'
    'click .enroll-selected-students': 'onClickBulkEnroll'

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
      @students.fetchForClassroom(@classroom)
      @supermodel.trackCollection(@students)
      @listenTo @students, 'sync', @sortByName
      @listenTo @students, 'sort', @render
      
      @classroom.sessions = new LevelSessions()
      @classroom.sessions.fetchForAllClassroomMembers(@classroom)
      @supermodel.trackCollection(@classroom.sessions)
      
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
    console.log("loaded!")
    
    @classCode = @classroom.get('codeCamel') || @classroom.get('code')
    @joinURL = document.location.origin + "/courses?_cc=" + @classCode
    
    @earliestIncompleteLevel = helper.calculateEarliestIncomplete(@classroom, @courses, @campaigns, @courseInstances, @students)
    @latestCompleteLevel = helper.calculateLatestComplete(@classroom, @courses, @campaigns, @courseInstances, @students)
    for student in @students.models
      # TODO: this is a weird hack
      studentsStub = new Users([ student ])
      student.latestCompleteLevel = helper.calculateLatestComplete(@classroom, @courses, @campaigns, @courseInstances, studentsStub)
      
    classroomsStub = new Classrooms([ @classroom ])
    @progressData = helper.calculateAllProgress(classroomsStub, @courses, @campaigns, @courseInstances, @students)
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
      console.log('Oops, unable to copy', err)

  onClickAddStudents: (e) =>
    modal = new InviteToClassroomModal({ classroom: @classroom })
    @openModalView(modal)
    @listenToOnce modal, 'hide', @render
    
  onClickEnrollStudent: (e) ->
    # TODO
  
  sortByName: (e) =>
    if @sortValue == 'name'
      @sortDirection = -@sortDirection
    else
      @sortValue = 'name'
      @sortDirection = 1
      
    dir = @sortDirection
    @students.comparator = (student1, student2) ->
      return (if student1.get('name') < student2.get('name') then -dir else dir)
    @students.sort()
    
  sortByProgress: (e) =>
    if @sortValue == 'progress'
      @sortDirection = -@sortDirection
    else
      @sortValue = 'progress'
      @sortDirection = 1
      
    dir = @sortDirection
    @students.comparator = (student1, student2) ->
      l1 = student1.latestCompleteLevel
      l2 = student2.latestCompleteLevel
      if l1.courseNumber < l2.courseNumber
        return -dir
      else if l1.levelNumber < l2.levelNumber
        return -dir
      else
        return dir
    @students.sort()
    
  onClickBulkAssign: ->
    courseID = $('.bulk-course-select').val()
    courseInstance = @courseInstances.getByCourseAndClassroom(courseID, @classroom)
    # TODO: Only assign the selected ones
    for student in @students
      courseInstance.addMember(student.id)

  onClickBulkEnroll: ->
    # TODO: AJAX for enrolling students. Needs a backend endpoint for multiple students? Or just do one-by-one like ActivateLicensesModal?
