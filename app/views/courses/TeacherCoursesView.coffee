app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
Classroom = require 'models/Classroom'
CourseInstance = require 'models/CourseInstance'
RootView = require 'views/core/RootView'
template = require 'templates/courses/teacher-courses-view'
utils = require 'core/utils'

# 

module.exports = class TeacherCoursesView extends RootView
  id: 'teacher-courses-view'
  template: template

  constructor: (options) ->
    super(options)
    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @supermodel.loadCollection(@courses, 'courses')
    @classrooms = new CocoCollection([], { url: "/db/classroom", model: Classroom })
    @listenToOnce @classrooms, 'sync', @onCourseInstancesLoaded
    @supermodel.loadCollection(@classrooms, 'classrooms', {data: {ownerID: me.id}})
    @
