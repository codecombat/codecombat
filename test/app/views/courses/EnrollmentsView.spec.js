/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const EnrollmentsView = require('views/courses/EnrollmentsView');
const Courses = require('collections/Courses');
const Prepaids = require('collections/Prepaids');
const Users = require('collections/Users');
const Classrooms = require('collections/Classrooms');
const factories = require('test/app/factories');
const TeachersContactModal = require('views/teachers/TeachersContactModal');

describe('EnrollmentsView', function() {

  beforeEach(function() {
    me.set('anonymous', false);
    me.set('role', 'teacher');
    me.set('enrollmentRequestSent', false);
    this.view = new EnrollmentsView();

    // Make three classrooms, sharing users from a pool of 10, 5 of which are enrolled
    const prepaid = factories.makePrepaid();
    const students = new Users(_.times(10, i => factories.makeUser({}, { prepaid: i%2 ? prepaid : null }))
    );

    const userSlices = [
      new Users(students.slice(0, 5)),
      new Users(students.slice(3, 8)),
      new Users(students.slice(7, 10))
    ];

    const classrooms = new Classrooms(Array.from(userSlices).map((userSlice) => factories.makeClassroom({}, {members: userSlice})));
    this.view.classrooms.fakeRequests[0].respondWith({ status: 200, responseText: classrooms.stringify() });
    for (let i = 0; i < this.view.members.fakeRequests.length; i++) {
      var request = this.view.members.fakeRequests[i];
      request.respondWith({status: 200, responseText: userSlices[i].stringify()});
    }

    // Make prepaids of various status
    const prepaids = new Prepaids([
      factories.makePrepaid({}, {redeemers: new Users(_.times(5, () => factories.makeUser()))}),
      factories.makePrepaid(),
      factories.makePrepaid({ // pending
        startDate: moment().add(2, 'months').toISOString(),
        endDate: moment().add(14, 'months').toISOString()
      }),
      factories.makePrepaid( // empty
        { maxRedeemers: 2 },
        {redeemers: new Users(_.times(2, () => factories.makeUser()))}
      )
    ]);
    this.view.prepaids.fakeRequests[0].respondWith({ status: 200, responseText: prepaids.stringify() });

    // Make a few courses, one free
    const courses = new Courses([
      factories.makeCourse({free: true}),
      factories.makeCourse({free: false}),
      factories.makeCourse({free: false}),
      factories.makeCourse({free: false})
    ]);
    this.view.courses.fakeRequests[0].respondWith({ status: 200, responseText: courses.stringify() });

    jasmine.demoEl(this.view.$el);
    return window.view = this.view;
  });

  describe('For low priority leads', function() {
    beforeEach(function() {
      const leadPriorityRequest = jasmine.Ajax.requests.filter(r => r.url === '/db/user/-/lead-priority')[0];
      return leadPriorityRequest.respondWith({status: 200, responseText: JSON.stringify({ priority: 'low' })});
    });

    // describe('shows the starter license upsell', function() {
    //   if (features.chinaInfra) { return; }
    // });
//      it 'when only subscription prepaids exist', ->
//        @view.prepaids.set([])
//        @view.prepaids.add(factories.makePrepaid({
//          type: 'subscription'
//          startDate: moment().subtract(3, 'weeks').toISOString()
//          endDate: moment().add(2, 'weeks').toISOString()
//        }))
//
//        @view.prepaids.trigger('sync')
//        @view.render()
//
//        expect(@view.$('a[href="/teachers/starter-licenses"]').length).toBe(1)
//
//      it 'when active starter licenses exist', ->
//        @view.prepaids.set([])
//        @view.prepaids.add(factories.makePrepaid({
//          type: 'starter_license'
//          startDate: moment().subtract(3, 'weeks').toISOString()
//          endDate: moment().add(2, 'weeks').toISOString()
//        }))
//
//        @view.prepaids.trigger('sync')
//        @view.render()
//
//        expect(@view.$('a[href="/teachers/starter-licenses"]').length).toBe(1)
//
//      it 'when expired starter licenses exist', ->
//        @view.prepaids.set([])
//        @view.prepaids.add(factories.makePrepaid({
//          type: 'starter_license'
//          startDate: moment().subtract(3, 'week').toISOString()
//          endDate: moment().subtract(1, 'week').toISOString()
//        }))
//
//        @view.prepaids.trigger('sync')
//        @view.render()
//
//        expect(@view.$('a[href="/teachers/starter-licenses"]').length).toBe(1)
//
//      it 'when no prepaids exist', ->
//        @view.prepaids.set([])
//
//        @view.prepaids.trigger('sync')
//        @view.render()
//
//        expect(@view.$('a[href="/teachers/starter-licenses"]').length).toBe(1)

    return describe('does not show the starter license upsell', function() {
      it('when full licenses have existed', function() {
        this.view.prepaids.set([]);
        this.view.prepaids.add(factories.makePrepaid({
          startDate: moment().subtract(2, 'month').toISOString(),
          endDate: moment().subtract(1, 'month').toISOString()
        }));

        this.view.render();
        return expect(this.view.$('a[href="/teachers/starter-licenses"]').length).toBe(0);
      });

      return it('when full licenses currently exist', function() {
        this.view.prepaids.set([]);
        this.view.prepaids.add(factories.makePrepaid({
          startDate: moment().subtract(2, 'month').toISOString(),
          endDate: moment().add(1, 'month').toISOString()
        }));

        this.view.render();
        return expect(this.view.$('a[href="/teachers/starter-licenses"]').length).toBe(0);
      });
    });
  });

  describe('For high priority leads', function() {
    beforeEach(function() {
      const leadPriorityRequest = jasmine.Ajax.requests.filter(r => r.url === '/db/user/-/lead-priority')[0];
      leadPriorityRequest.respondWith({status: 200, responseText: JSON.stringify({ priority: 'high' })});
      return this.view.render();
    });

    return it("doesn't show the Starter License upsell", function() {
      return expect(this.view.$('a[href="/teachers/starter-licenses"]').length).toBe(0);
    });
  });

  return describe('For no priority leads', function() {
    beforeEach(function() {
      const leadPriorityRequest = jasmine.Ajax.requests.filter(r => r.url === '/db/user/-/lead-priority')[0];
      leadPriorityRequest.respondWith({status: 200, responseText: JSON.stringify({ priority: undefined })});
      return this.view.render();
    });

    it("doesn't show the Starter License upsell", function() {
      return expect(this.view.$('a[href="/teachers/starter-licenses"]').length).toBe(0);
    });

    describe('"Get Licenses" area', () => describe('when the teacher has made contact', function() {
      beforeEach(function() {
        this.view.enrollmentRequestSent = true;
        return this.view.render();
      });

      return it('shows confirmation and a mailto link to schools@codecombat.com', function() {
        if (!this.view.$('#request-sent-btn').length) {
          fail('Request button not found.');
        }
        if (!this.view.$('#enrollment-request-sent-blurb').length) {
          return fail('License request sent blurb not found.');
        }
      });
    }));
          // TODO: Figure out why this fails in Travis. Seems like it's not loading en locale
  //        if not @view.$('a[href="mailto:schools@codecombat.com"]').length
  //          fail('Mailto: link not found.')

    return describe('when there are no prepaids to show', function() {
      beforeEach(function(done) {
        this.view.prepaids.reset([]);
        this.view.updatePrepaidGroups();
        return _.defer(done);
      });

      return it('fills the void with the rest of the page content', function() {
        return expect(this.view.$('#actions-col').length).toBe(0);
      });
    });
  });
});
