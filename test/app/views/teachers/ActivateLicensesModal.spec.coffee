ActivateLicensesModal = require 'views/courses/ActivateLicensesModal'
Classrooms = require 'collections/Classrooms'
Courses = require 'collections/Courses'
Levels = require 'collections/Levels'
Prepaids = require 'collections/Prepaids'
Users = require 'collections/Users'
forms = require 'core/forms'
factories = require 'test/app/factories'

# Needs some fixing
describe 'ActivateLicensesModal', ->

  beforeEach (done) ->
    @members = new Users(_.times(4, (i) -> factories.makeUser()))
    @classrooms = new Classrooms([
      factories.makeClassroom({}, { @members })
      factories.makeClassroom()
    ])
    selectedUsers = new Users(@members.slice(0,3))
    options = _.extend({}, {
      classroom: @classrooms.first(), @classrooms, users: @members, selectedUsers
    }, options)
    @modal = new ActivateLicensesModal(options)
    @prepaidThatExpiresSooner = factories.makePrepaid({maxRedeemers: 1, endDate: moment().add(1, 'month').toISOString()})
    @prepaidThatExpiresLater = factories.makePrepaid({maxRedeemers: 1, endDate: moment().add(2, 'months').toISOString()})
    prepaids = new Prepaids([
      # empty
      factories.makePrepaid({maxRedeemers: 0, endDate: moment().add(1, 'day').toISOString()})
      
      # expired
      factories.makePrepaid({maxRedeemers: 10, endDate: moment().subtract(1, 'day').toISOString()})
        
      # pending
      factories.makePrepaid({
        maxRedeemers: 100
        startDate: moment().add(1, 'month').toISOString()
        endDate: moment().add(2, 'months').toISOString()
      })

      # these should be used
      @prepaidThatExpiresSooner
      @prepaidThatExpiresLater
    ])
    @modal.prepaids.fakeRequests[0].respondWith({ status: 200, responseText: prepaids.stringify() })
    @modal.classrooms.fakeRequests[0].respondWith({
      status: 200
      responseText: @classrooms.stringify()
    })
    @modal.classrooms.first().users.fakeRequests[0].respondWith({
      status: 200
      responseText: @members.stringify()
    })

    jasmine.demoModal(@modal)
    _.defer done
  
  describe 'the class dropdown', ->
    it 'contains an All Students option', ->
      expect(@modal.$('select option:last-child').data('i18n')).toBe('teacher.all_students')
    
    it 'displays the current classname', ->
      expect(@modal.$('option:selected').html()).toBe(@classrooms.first().get('name'))
    
    it 'contains all of the teacher\'s classes', ->
      expect(@modal.$('select option').length).toBe(3) # including 'All Students' options
    
  describe 'the checklist of students', ->
    it 'should separate the unenrolled from the enrolled students'
    
    it 'should have a checkmark by the selected students'

    it 'should display all the students'
      
  
  describe 'the credits availble count', ->
    it 'should match the number of unused prepaids', ->
      expect(@modal.$('#total-available').html()).toBe('2')

  describe 'the Enroll button', ->
    it 'should show the number of selected students', ->
      expect(@modal.$('#total-selected-span').html()).toBe('3')
    
    it 'should fire off one request when clicked'
    
    describe 'when the teacher has enough licenses', ->
      beforeEach ->
        selected = @modal.state.get('selectedUsers')
        selected.remove(selected.first())
        
      it 'should be enabled', ->
        expect(@modal.$('#activate-licenses-btn').hasClass('disabled')).toBe(false)
        
      describe 'when clicked', ->
        beforeEach ->
          @modal.$('form').submit()
        
        it 'enrolls the selected students with the soonest-to-expire, available prepaid', ->
          request = jasmine.Ajax.requests.mostRecent()
          if request.url.indexOf(@prepaidThatExpiresSooner.id) is -1
            fail('The first prepaid should be the prepaid that expires sooner')
          request.respondWith({ status: 200, responseText: '{ "redeemers": [{}] }' })
          request = jasmine.Ajax.requests.mostRecent()
          if request.url.indexOf(@prepaidThatExpiresLater.id) is -1
            fail('The second prepaid should be the prepaid that expires later')
  
    describe 'when the teacher doesn\'t have enough licenses', ->
      it 'should be disabled', ->
        expect(@modal.$('#activate-licenses-btn').hasClass('disabled')).toBe(true)
        
  describe 'the Purchase More button', ->
    it 'should redirect to the license purchasing page'
    
  
      
    
  
  #
  # describe 'enroll button', ->
  #   beforeEach (done) ->
    #   makeModal.bind(this)(done)
  #
  #   it 'should display the correct total number of credits', ->
  #     expect(@modal.$('#total-available').html()).toBe('2')
  #
  #   it 'should be disabled when teacher doesn\'t have enough licenses', ->
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
