TeacherClassView = require 'views/courses/TeacherClassView'
storage = require 'core/storage'
forms = require 'core/forms'

describe '/teachers/classes/:handle', ->
  
describe 'TeacherClassView', ->
  
  # describe 'when logged out', ->
  #   it 'responds with 401 error'
  #   it 'shows Log In and Create Account buttons'
  
  @view = null
    
  # describe "when you don't own the class", ->
  #   it 'responds with 403 error'
  #   it 'shows Log Out button'
    
  describe 'when logged in', ->
    beforeEach (done) ->
      me = require 'test/app/fixtures/teacher'
      @classroom = require 'test/app/fixtures/classrooms/active-classroom'
      @students = require 'test/app/fixtures/students'
      @courses = require 'test/app/fixtures/courses'
      @campaigns = require 'test/app/fixtures/campaigns'
      @courseInstances = require 'test/app/fixtures/course-instances'
      @levelSessions = require 'test/app/fixtures/level-sessions-partially-completed'
      
      @view = new TeacherClassView()
      @view.classroom.fakeRequests.forEach (r, index) => r.respondWith({ status: 200, responseText: JSON.stringify(@classroom) })
      @view.courses.fakeRequests.forEach (r, index) => r.respondWith({ status: 200, responseText: JSON.stringify(@courses) })
      @view.campaigns.fakeRequests.forEach (r, index) => r.respondWith({ status: 200, responseText: JSON.stringify(@campaigns) })
      @view.courseInstances.fakeRequests.forEach (r, index) => r.respondWith({ status: 200, responseText: JSON.stringify(@courseInstances) })
      @view.students.fakeRequests.forEach (r, index) => r.respondWith({ status: 200, responseText: JSON.stringify(@students) })
      @view.classroom.sessions.fakeRequests.forEach (r, index) => r.respondWith({ status: 200, responseText: JSON.stringify(@levelSessions) })
      
      jasmine.demoEl(@view.$el)
      _.defer done
    
    it 'has contents', ->
      expect(@view.$el.children().length).toBeGreaterThan(0)

      
    # it "shows the classroom's name and description"
    # it "shows the classroom's join code"
    
    describe 'the Students tab', ->
      # it 'shows all of the students'
      # it 'sorts correctly by Name'
      # it 'sorts correctly by Progress'
      
      describe 'bulk-assign controls', ->
        it 'shows alert when assigning course 2 to unenrolled students', ->
          expect(@view.$('.cant-assign-to-unenrolled').hasClass('visible')).toBe(false)
          @view.$('.student-row .checkbox-flat').click()
          @view.$('.assign-to-selected-students').click()
          expect(@view.$('.cant-assign-to-unenrolled').hasClass('visible')).toBe(true)
          
        it 'shows alert when assigning but no students are selected', ->
          expect(@view.$('.no-students-selected').hasClass('visible')).toBe(false)
          @view.$('.assign-to-selected-students').click()
          expect(@view.$('.no-students-selected').hasClass('visible')).toBe(true)
    
    # describe 'the Course Progress tab', ->
    #   it 'shows the correct Course Overview progress'
    #
    #   describe 'when viewing another course'
    #     it 'still shows the correct Course Overview progress'
    #
    
      
    
    
    
