/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const ActivateLicensesModal = require('views/courses/ActivateLicensesModal');
const Classrooms = require('collections/Classrooms');
const Courses = require('collections/Courses');
const Levels = require('collections/Levels');
const Prepaids = require('collections/Prepaids');
const Users = require('collections/Users');
const forms = require('core/forms');
const factories = require('test/app/factories');

// Needs some fixing
describe('ActivateLicensesModal', function() {

  beforeEach(function(done) {
    this.members = new Users(_.times(4, i => factories.makeUser()));
    this.classrooms = new Classrooms([
      factories.makeClassroom({}, { members: this.members }),
      factories.makeClassroom()
    ]);
    const selectedUsers = new Users(this.members.slice(0,3));
    var options = _.extend({}, {
      classroom: this.classrooms.first(), classrooms: this.classrooms, users: this.members, selectedUsers
    }, options);
    this.modal = new ActivateLicensesModal(options);
    this.prepaidThatExpiresSooner = factories.makePrepaid({maxRedeemers: 1, endDate: moment().add(1, 'month').toISOString()});
    this.prepaidThatExpiresLater = factories.makePrepaid({maxRedeemers: 1, endDate: moment().add(2, 'months').toISOString()});
    const prepaids = new Prepaids([
      // empty
      factories.makePrepaid({maxRedeemers: 0, endDate: moment().add(1, 'day').toISOString()}),
      
      // expired
      factories.makePrepaid({maxRedeemers: 10, endDate: moment().subtract(1, 'day').toISOString()}),
        
      // pending
      factories.makePrepaid({
        maxRedeemers: 100,
        startDate: moment().add(1, 'month').toISOString(),
        endDate: moment().add(2, 'months').toISOString()
      }),

      // these should be used
      this.prepaidThatExpiresSooner,
      this.prepaidThatExpiresLater
    ]);
    this.modal.prepaids.fakeRequests[0].respondWith({ status: 200, responseText: prepaids.stringify() });
    this.modal.classrooms.fakeRequests[0].respondWith({
      status: 200,
      responseText: this.classrooms.stringify()
    });
    this.modal.classrooms.first().users.fakeRequests[0].respondWith({
      status: 200,
      responseText: this.members.stringify()
    });

    jasmine.demoModal(this.modal);
    return _.defer(done);
  });
  
  describe('the class dropdown', function() {
    it('contains an All Students option', function() {
      return expect(this.modal.$('select option:last-child').data('i18n')).toBe('teacher.all_students');
    });
    
    it('displays the current classname', function() {
      return expect(this.modal.$('option:selected').html()).toBe(this.classrooms.first().get('name'));
    });
    
    return it('contains all of the teacher\'s classes', function() {
      return expect(this.modal.$('select option').length).toBe(3);
    });
  }); // including 'All Students' options
    
  describe('the checklist of students', function() {
    it('should separate the unenrolled from the enrolled students');
    
    it('should have a checkmark by the selected students');

    return it('should display all the students');
  });
      
  
  describe('the credits availble count', () => it('should match the number of unused prepaids', function() {
    return expect(this.modal.$('#total-available').html()).toBe('2');
  }));

  describe('the Enroll button', function() {
    it('should show the number of selected students', function() {
      return expect(this.modal.$('#total-selected-span').html()).toBe('3');
    });
    
    it('should fire off one request when clicked');
    
    describe('when the teacher has enough licenses', function() {
      beforeEach(function() {
        const selected = this.modal.state.get('selectedUsers');
        selected.remove(selected.first());
        return selected.remove(selected.first());
      });
        
      it('should be enabled', function() {
        return expect(this.modal.$('#activate-licenses-btn').hasClass('disabled')).toBe(false);
      });
        
      return describe('when clicked', function() {
        beforeEach(function() {
          return this.modal.$('form').submit();
        });
        
        return it('enrolls the selected students with the selected prepaid', function() {
          const request = jasmine.Ajax.requests.mostRecent();
          if (request.url.indexOf(this.prepaidThatExpiresSooner.id) === -1) {
            fail('The first prepaid should be the prepaid that expires sooner');
          }
          return request.respondWith({ status: 200, responseText: '{ "redeemers": [{}] }' });
        });
      });
    });
  
    return describe('when the teacher doesn\'t have enough licenses', () => it('should be disabled', function() {
      return expect(this.modal.$('#activate-licenses-btn').hasClass('disabled')).toBe(true);
    }));
  });
        
  return describe('the Purchase More button', () => it('should redirect to the license purchasing page'));
});
    
  
      
    
  
  //
  // describe 'enroll button', ->
  //   beforeEach (done) ->
    //   makeModal.bind(this)(done)
  //
  //   it 'should display the correct total number of credits', ->
  //     expect(@modal.$('#total-available').html()).toBe('2')
  //
  //   it 'should be disabled when teacher doesn\'t have enough licenses', ->
  //     expect(@modal.$('#total-available').html()).toBe('2')
  //
  //
  //
  // describe 'when enrolling only a single student', ->
  //   describe 'the list of students', ->
  //     it 'should only have the one student selected'
  //
  // describe 'when bulk-enrolling students', ->
  //   describe 'the list of students', ->
  //     it 'should have the right students selected'
  //
  // describe 'selecting more students', ->
  //   it 'should increase the student counter'
