ActivateLicensesModal = require 'views/courses/ActivateLicensesModal'
Users = require 'collections/Users'
forms = require 'core/forms'

# Needs some fixing
xdescribe 'ActivateLicensesModal', ->
  
  @modal = null
  
  me = require 'test/app/fixtures/teacher'
  prepaids = require 'test/app/fixtures/prepaids'
  classrooms = require 'test/app/fixtures/classrooms/unarchived-classrooms'
  users = require 'test/app/fixtures/students'
  responses = {
    '/db/prepaid': prepaids.toJSON()
    '/db/classroom': classrooms.toJSON()
    # '/members': users.toJSON() # TODO: Respond with different ones for different classrooms
  }
  
  makeModal = (options) ->
    (done) ->
      @selectedUsers = new Users(@users.models.slice(0,(options?.numSelected or 3)))
      @modal = new ActivateLicensesModal({
        @classroom, @users, @selectedUsers
      })
      jasmine.Ajax.requests.sendResponses(responses)
      _.filter(jasmine.Ajax.requests.all().slice(), (request) ->
        /\/db\/classroom\/.*\/members/.test(request.url) and request.readyState < 4
      ).forEach (request) ->
        request.respondWith(users.toJSON)
      # debugger
        
      jasmine.demoModal(@modal)
      _.defer done
    
  beforeEach ->
    @classroom = classrooms.get('active-classroom')
    @users = require 'test/app/fixtures/students'
        
  afterEach ->
    @modal.stopListening()
  
  describe 'the class dropdown', ->
    beforeEach makeModal()
    
    # punted indefinitely
    xit 'should contain an All Students option', ->
      expect(@modal.$('select option:last-child').html()).toBe('All Students')
    
    it 'should display the current classname', ->
      expect(@modal.$('option:selected').html()).toBe('Teacher Zero\'s Classroomiest Classroom')
    
    it 'should contain all of the teacher\'s classes'
    
    it 'shouldn\'t contain anyone else\'s classrooms'
    
  describe 'the checklist of students', ->
    it 'should separate the unenrolled from the enrolled students'
    
    it 'should have a checkmark by the selected students'

    it 'should display all the students'
      
  
  describe 'the credits availble count', ->
    beforeEach makeModal()
    it 'should match the number of unused prepaids', ->
      expect(@modal.$('#total-available').html()).toBe('2')

  describe 'the Enroll button', ->
    beforeEach makeModal()
    it 'should show the number of selected students', ->
      expect(@modal.$('#total-selected-span').html()).toBe('3')
    
    it 'should fire off one request when clicked'
    
    describe 'when the teacher has enough enrollments', ->
      beforeEach makeModal({ numSelected: 2 })
      it 'should be enabled', ->
        expect(@modal.$('#activate-licenses-btn').hasClass('disabled')).toBe(false)
  
    describe 'when the teacher doesn\'t have enough enrollments', ->
      it 'should be disabled', ->
        expect(@modal.$('#activate-licenses-btn').hasClass('disabled')).toBe(true)
        
  describe 'the Purchase More button', ->
    it 'should redirect to the enrollment purchasing page'
    
  
      
    
  
  #
  # describe 'enroll button', ->
  #   beforeEach (done) ->
    #   makeModal.bind(this)(done)
  #
  #   it 'should display the correct total number of credits', ->
  #     expect(@modal.$('#total-available').html()).toBe('2')
  #
  #   it 'should be disabled when teacher doesn\'t have enough enrollments', ->
  #     expect(@modal.$('#total-available').html()).toBe('2')
  #
  #
  #
  # describe 'when enrolling only a single student', ->
  #   describe 'the list of students', ->
  #     it 'should only have the one student selected'
  #
  # describe 'when bulk-enrolling students', ->
  #   describe 'the list of students', ->
  #     it 'should have the right students selected'
  #
  # describe 'selecting more students', ->
  #   it 'should increase the student counter'
