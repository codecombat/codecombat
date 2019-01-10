CoursesView = require 'views/courses/CoursesView'
HeroSelectModal = require 'views/courses/HeroSelectModal'
# Levels = require 'collections/Levels'
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

    it 'opens the modal when you click Change Hero', ->
      spyOn(view, 'openModalView')
      view.$('.change-hero-btn').click()
      expect(view.openModalView).toHaveBeenCalled()
      args = view.openModalView.calls.argsFor(0)
      expect(args[0] instanceof HeroSelectModal).toBe(true)


  # TODO: this test case is in progress
  describe 'view videos link', ->
    beforeEach (done) ->
      user = factories.makeUser({ role: 'student' })
      me.set(user.attributes)
      # levels = new Levels(_.times(2, -> factories.makeLevel({ concepts: ['basic_syntax', 'arguments', 'functions'] })))
      # levels.push(factories.makeLevel({ name: "Practice Level", concepts: ['basic_syntax', 'arguments', 'functions'], practice: true }))
      # levels.push(factories.makeLevel({ concepts: ['basic_syntax', 'arguments', 'functions'], primerLanguage: 'javascript' }))
      courses = new Courses([factories.makeCourse({name: 'Introduction to Computer Science'})])
      classroom = factories.makeClassroom({ aceConfig: { language: 'python' }, courses: courses })
      courseInstances = new CourseInstances([ factories.makeCourseInstance({}, { course: courses.first(), classroom}) ])
      @view = new CoursesView()
      @view.classrooms.fakeRequests[0].respondWith({ status: 200, responseText: classroom.stringify() })
      @view.ownedClassrooms.fakeRequests[0].respondWith({ status: 200, responseText: classroom.stringify() })
      @view.courseInstances.fakeRequests[0].respondWith({ status: 200, responseText: courseInstances.stringify() })
      @view.render()
      jasmine.demoEl(@view.$el)
      done()

    it 'navigates to CourseVideosView', ->
      console.log("here")
    # #   spyOn(application.router, 'navigate')
      console.log(@view)
      @view.$el.find('.view-videos-link').click()
      console.log(@view.$el.find('.view-videos-link'))
      # expect(view.$('.view-videos-link').length).toBe(1)
      # expect(application.router.navigate).toHaveBeenCalled()
      # Backbone.history.loadUrl("/students/videos/#{@courseId}/#{@courseName}")
      # expect(application.router.navigate.calls.count()).toBe(1)
      # args = application.router.navigate.calls.argsFor(0)
