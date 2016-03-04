RootView = require 'views/core/RootView'
template = require 'templates/courses/teacher-class-view'
helper = require 'lib/coursesHelper'

Classroom = require 'models/Classroom'
LevelSessions = require 'collections/LevelSessions'
Users = require 'collections/Users'

module.exports = class TeacherClassView extends RootView
  id: 'teacher-class-view'
  template: template
  
  initialize: (options, classroomID) ->
    super(options)
    @classroom = new Classroom({ _id: classroomID })
    @classroom.fetch()
    @listenTo @classroom, 'sync', ->
      @students = new Users()
      @students.fetchForClassroom(@classroom)
      @supermodel.trackCollection(@students)
    @supermodel.trackModel(@classroom)

  onLoaded: ->
    console.log("loaded!")
    @classroom.sessions = new LevelSessions()
    @classroom.sessions.fetchForAllClassroomMembers(@classroom)
    super()
