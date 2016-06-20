TeacherClassView = require 'views/courses/TeacherClassView'
storage = require 'core/storage'
forms = require 'core/forms'
factories = require 'test/app/factories'
Users = require 'collections/Users'
Courses = require 'collections/Courses'
Levels = require 'collections/Levels'
LevelSessions = require 'collections/LevelSessions'
CourseInstances = require 'collections/CourseInstances'

describe '/teachers/classes/:handle', ->
  
describe 'TeacherClassView', ->
  
  # describe 'when logged out', ->
  #   it 'responds with 401 error'
  #   it 'shows Log In and Create Account buttons'
  
  # describe "when you don't own the class", ->
  #   it 'responds with 403 error'
  #   it 'shows Log Out button'
    
  describe 'when logged in', ->
    beforeEach (done) ->
      me = factories.makeUser({})
      
      @courses = new Courses([factories.makeCourse({name: 'First Course'}), factories.makeCourse({name: 'Second Course'})])
      available = factories.makePrepaid()
      expired = factories.makePrepaid({endDate: moment().subtract(1, 'day').toISOString()})
      @students = new Users([
        factories.makeUser({name: 'Abner'})
        factories.makeUser({name: 'Abigail'})
        factories.makeUser({name: 'Abby'}, {prepaid: available})
        factories.makeUser({name: 'Ben'}, {prepaid: available})
        factories.makeUser({name: 'Ned'}, {prepaid: expired})
        factories.makeUser({name: 'Ebner'}, {prepaid: expired})
      ])
      @levels = new Levels(_.times(2, -> factories.makeLevel()))
      @classroom = factories.makeClassroom({}, { @courses, members: @students, levels: [@levels, new Levels()] })
      @courseInstances = new CourseInstances([
        factories.makeCourseInstance({}, { course: @courses.first(), @classroom, members: @students })
        factories.makeCourseInstance({}, { course: @courses.last(), @classroom, members: @students })
      ])

      sessions = []
      @finishedStudent = @students.first()
      @unfinishedStudent = @students.last()
      for level in @levels.models
        sessions.push(factories.makeLevelSession(
            {state: {complete: true}},
            {level, creator: @finishedStudent})
        )
      sessions.push(factories.makeLevelSession(
          {state: {complete: true}},
          {level: @levels.first(), creator: @unfinishedStudent})
      )
      @levelSessions = new LevelSessions(sessions)
      
      @view = new TeacherClassView({}, @courseInstances.first().id)
      @view.classroom.fakeRequests[0].respondWith({ status: 200, responseText: @classroom.stringify() })
      @view.courses.fakeRequests[0].respondWith({ status: 200, responseText: @courses.stringify() })
      @view.courseInstances.fakeRequests[0].respondWith({ status: 200, responseText: @courseInstances.stringify() })
      @view.students.fakeRequests[0].respondWith({ status: 200, responseText: @students.stringify() })
      @view.classroom.sessions.fakeRequests[0].respondWith({ status: 200, responseText: @levelSessions.stringify() })
      @view.levels.fakeRequests[0].respondWith({ status: 200, responseText: @levels.stringify() })
      
      jasmine.demoEl(@view.$el)
      _.defer done
    
    it 'has contents', ->
      expect(@view.$el.children().length).toBeGreaterThan(0)

      
    # it "shows the classroom's name and description"
    # it "shows the classroom's join code"
    
    describe 'the Students tab', ->
      beforeEach (done) ->
        @view.state.set('activeTab', '#students-tab')
        _.defer(done)

      # it 'shows all of the students'
      # it 'sorts correctly by Name'
      # it 'sorts correctly by Progress'
      
      describe 'bulk-assign controls', ->
        it 'shows alert when assigning course 2 to unenrolled students', (done) ->
          expect(@view.$('.cant-assign-to-unenrolled').hasClass('visible')).toBe(false)
          @view.$('.student-row .checkbox-flat').click()
          @view.$('.assign-to-selected-students').click()
          _.defer =>
            expect(@view.$('.cant-assign-to-unenrolled').hasClass('visible')).toBe(true)
            done()
          
        it 'shows alert when assigning but no students are selected', (done) ->
          expect(@view.$('.no-students-selected').hasClass('visible')).toBe(false)
          @view.$('.assign-to-selected-students').click()
          _.defer =>
            expect(@view.$('.no-students-selected').hasClass('visible')).toBe(true)
            done()
    
    # describe 'the Course Progress tab', ->
    #   it 'shows the correct Course Overview progress'
    #
    #   describe 'when viewing another course'
    #     it 'still shows the correct Course Overview progress'
    #
    
    describe 'the Enrollment Status tab', ->
      beforeEach ->
        @view.state.set('activeTab', '#enrollment-status-tab')
      
      describe 'Enroll button', ->
        it 'calls enrollStudents with that user when clicked', ->
          spyOn(@view, 'enrollStudents')
          @view.$('.enroll-student-button:first').click()
          expect(@view.enrollStudents).toHaveBeenCalled()
          users = @view.enrollStudents.calls.argsFor(0)[0]
          expect(users.size()).toBe(1)
          expect(users.first().id).toBe(@view.students.first().id)
