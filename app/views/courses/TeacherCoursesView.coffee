app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
CocoCollection = require 'collections/CocoCollection'
CocoModel = require 'models/CocoModel'
Course = require 'models/Course'
Classroom = require 'models/Classroom'
InviteToClassroomModal = require 'views/courses/InviteToClassroomModal'
User = require 'models/User'
CourseInstance = require 'models/CourseInstance'
RootView = require 'views/core/RootView'
template = require 'templates/courses/teacher-courses-view'
ClassroomSettingsModal = require 'views/courses/ClassroomSettingsModal'

module.exports = class TeacherCoursesView extends RootView
  id: 'teacher-courses-view'
  template: template

  events:
    'click .btn-add-students': 'onClickAddStudents'
    'click .create-new-class': 'onClickCreateNewClassButton'
    'click .edit-classroom-small': 'onClickEditClassroomSmall'

  constructor: (options) ->
    super(options)
    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @supermodel.loadCollection(@courses, 'courses')
    @classrooms = new CocoCollection([], { url: "/db/classroom", model: Classroom })
    @classrooms.comparator = '_id'
    @listenToOnce @classrooms, 'sync', @onceClassroomsSync
    @supermodel.loadCollection(@classrooms, 'classrooms', {data: {ownerID: me.id}})
    @courseInstances = new CocoCollection([], { url: "/db/course_instance", model: CourseInstance })
    @courseInstances.comparator = 'courseID'
    @courseInstances.sliceWithMembers = -> return @filter (courseInstance) -> _.size(courseInstance.get('members')) and courseInstance.get('classroomID')
    @supermodel.loadCollection(@courseInstances, 'course_instances', {data: {ownerID: me.id}})
    @members = new CocoCollection([], { model: User })
    @listenTo @members, 'sync', @render
    @

  onceClassroomsSync: ->
    for classroom in @classrooms.models
      @members.fetch({
        remove: false
        url: "/db/classroom/#{classroom.id}/members"
      })

  onClickAddStudents: (e) ->
    classroomID = $(e.target).data('classroom-id')
    classroom = @classrooms.get(classroomID)
    unless classroom
      console.error 'No classroom ID found.'
      return
    modal = new InviteToClassroomModal({classroom: classroom})
    @openModalView(modal)

  onClickCreateNewClassButton: ->
    return @openModalView new AuthModal() if me.get('anonymous')
    modal = new ClassroomSettingsModal({})
    @openModalView(modal)
    @listenToOnce modal, 'hide', =>
      # TODO: how to get new classroom from modal?
      @classrooms.add(modal.classroom)
      # TODO: will this definitely fire after modal saves new classroom?
      @listenToOnce modal.classroom, 'sync', @render

  onClickEditClassroomSmall: (e) ->
    classroomID = $(e.target).data('classroom-id')
    classroom = @classrooms.get(classroomID)
    modal = new ClassroomSettingsModal({classroom: classroom})
    @openModalView(modal)
    @listenToOnce modal, 'hide', @render
