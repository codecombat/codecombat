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

    it 'opens the modal when you click Change Hero', ->
      spyOn(view, 'openModalView')
      view.$('.change-hero-btn').click()
      expect(view.openModalView).toHaveBeenCalled()
      args = view.openModalView.calls.argsFor(0)
      expect(args[0] instanceof HeroSelectModal).toBe(true)
