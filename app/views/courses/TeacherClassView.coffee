RootView = require 'views/core/RootView'
template = require 'templates/courses/teacher-class-view'
helper = require 'lib/coursesHelper'
InviteToClassroomModal = require 'views/courses/InviteToClassroomModal'

Classroom = require 'models/Classroom'
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

  initialize: (options, classroomID) ->
    super(options)
    @classroom = new Classroom({ _id: classroomID })
    @classroom.fetch()
    @supermodel.trackModel(@classroom)
    
    @listenTo @classroom, 'sync', ->
      @students = new Users()
      @students.fetchForClassroom(@classroom)
      @supermodel.trackCollection(@students)
      
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
    @earliestIncompleteLevel =  helper.calculateEarliestIncomplete(@classroom, @courses, @campaigns, @courseInstances, @students)
    @latestCompleteLevel =  helper.calculateLatestComplete(@classroom, @courses, @campaigns, @courseInstances, @students)
    super()

  onClickAddStudents: (e) =>
    modal = new InviteToClassroomModal({ classroom: @classroom })
    @openModalView(modal)
    @listenToOnce modal, 'hide', @render
