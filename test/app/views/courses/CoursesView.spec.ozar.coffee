CoursesView = require 'views/courses/CoursesView'
HeroSelectModal = require 'views/courses/HeroSelectModal'
Classrooms = require 'collections/Classrooms'
CourseInstances = require 'collections/CourseInstances'
Courses = require 'collections/Courses'
auth = require 'core/auth'
factories = require 'test/app/factories'

describe 'CoursesView', ->

  modal = null
  view = null

  describe 'Change Hero button', ->
    beforeEach (done) ->
      me.set(factories.makeUser({ role: 'student' }).attributes)
      view = new CoursesView()
      classrooms = new Classrooms([factories.makeClassroom()])
      courseInstances = new CourseInstances([factories.makeCourseInstance()])
      courses = new Courses([factories.makeCourse()])
      view.classrooms.fakeRequests[0].respondWith({ status: 200, responseText: classrooms.stringify() })
      view.ownedClassrooms.fakeRequests[0].respondWith({ status: 200, responseText: classrooms.stringify() })
      view.courseInstances.fakeRequests[0].respondWith({ status: 200, responseText: courseInstances.stringify() })
      view.render()
      jasmine.demoEl(view.$el)
      done()
