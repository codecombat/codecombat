ActivateLicensesModal = require 'views/courses/ActivateLicensesModal'
Users = require 'collections/Users'
forms = require 'core/forms'

describe 'ActivateLicensesModal', ->
  
  @modal = null
  
  me = require 'test/app/fixtures/teacher'
  prepaids = require 'test/app/fixtures/prepaids'
  responses = {
    prepaids: {
      status: 200
      responseText: JSON.stringify(prepaids.toJSON())
    }
  }
  
  makeModal = (options) ->
    (done) ->
      @selectedUsers = new Users(@users.models.slice(0,3))
      @modal = new ActivateLicensesModal({
        @classroom, @users, @selectedUsers
      })
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith(responses.prepaids)
      jasmine.demoModal(@modal)
      _.defer done
    
  beforeEach ->
    @classroom = (require 'test/app/fixtures/classrooms').first()
    @users = require 'test/app/fixtures/students'
        
  afterEach ->
    @modal.stopListening()
  
  describe 'the class dropdown', ->
    it 'should display the current classname'
    
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
    beforeEach makeModal() # TODO: Rudundant in later tests
    it 'should show the number of selected students', ->
      expect(@modal.$('#total-selected-span').html()).toBe('3')
    
    it 'should fire off one request when clicked'
    
    describe 'when the teacher has enough enrollments', ->
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
