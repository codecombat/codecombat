app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
Classroom = require 'models/Classroom'
CourseInstance = require 'models/CourseInstance'
RootView = require 'views/core/RootView'
template = require 'templates/courses/teacher-courses-view'
utils = require 'core/utils'
InviteToClassroomModal = require 'views/courses/InviteToClassroomModal' 

module.exports = class TeacherCoursesView extends RootView
  id: 'teacher-courses-view'
  template: template
  
  events:
    'click #create-new-class-btn': 'onClickCreateNewclassButton'
    'click .add-students-btn': 'onClickAddStudentsButton'

  constructor: (options) ->
    super(options)
    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @supermodel.loadCollection(@courses, 'courses')
    @classrooms = new CocoCollection([], { url: "/db/classroom", model: Classroom })
    @listenToOnce @classrooms, 'sync', @onCourseInstancesLoaded
    @supermodel.loadCollection(@classrooms, 'classrooms', {data: {ownerID: me.id}})
    @

  onClickCreateNewclassButton: ->
    name = @$('#new-classroom-name-input').val()
    return unless name
    classroom = new Classroom({ name: name })
    classroom.save()
    @classrooms.add(classroom)
    classroom.saving = true
    @render()
    @listenTo classroom, 'sync', ->
      classroom.saving = false
      @render()

  onClickAddStudentsButton: (e) ->
    classroomID = $(e.target).data('classroom-id')
    classroom = @classrooms.get(classroomID)
    modal = new InviteToClassroomModal({classroom: classroom})
    @openModalView(modal)