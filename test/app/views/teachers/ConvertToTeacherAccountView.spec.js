/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const ConvertToTeacherAccountView = require('views/teachers/ConvertToTeacherAccountView');
const storage = require('core/storage');
const forms = require('core/forms');

describe('/teachers/update-account', function() {
  describe('when logged out', () => it('redirects to /teachers/signup', function() {
    spyOn(me, 'isAnonymous').and.returnValue(true);
    spyOn(application.router, 'navigate');
    Backbone.history.loadUrl('/teachers/update-account');
    expect(application.router.navigate.calls.count()).toBe(1);
    const args = application.router.navigate.calls.argsFor(0);
    return expect(args[0]).toBe('/teachers/signup');
  }));

  return describe('when logged in', () => it('displays ConvertToTeacherAccountView', function() {
    spyOn(me, 'isAnonymous').and.returnValue(false);
    spyOn(me, 'isTeacher').and.returnValue(false);
    spyOn(application.router, 'routeDirectly');
    Backbone.history.loadUrl('/teachers/update-account');
    expect(application.router.routeDirectly.calls.count()).toBe(1);
    const args = application.router.routeDirectly.calls.argsFor(0);
    return expect(args[0]).toBe('teachers/ConvertToTeacherAccountView');
  }));
});


describe('ConvertToTeacherAccountView (/teachers/update-account)', function() {

  let view = null;

  const successForm = {
    phoneNumber: '555-555-5555',
    role: 'Teacher',
    organization: 'School',
    district: 'District',
    city: 'Springfield',
    state: 'AL',
    country: 'United States',
    numStudents: '1-10',
    educationLevel: ['Middle'],
    firstName: 'Mr',
    lastName: 'Bean'
  };

  beforeEach(function() {
    spyOn(application.router, 'navigate');
    me.clear();
    me.set({
      _id: '1234',
      anonymous: false,
      email: 'some@email.com',
      name: 'Existing User'
    });
    me._revertAttributes = {};
    view = new ConvertToTeacherAccountView();
    view.render();
    jasmine.demoEl(view.$el);

    return spyOn(storage, 'load').and.returnValue({ lastName: 'Saved Changes' });
  });
    
  afterEach(done => _.defer(done)); // let everything finish loading, keep navigate spied on

  describe('when the form is unchanged', () => it('does not prevent navigating away', () => expect(_.result(view, 'onLeaveMessage')).toBeFalsy()));

  describe('when the form has changed but is not submitted', function() {
    beforeEach(() => view.$el.find('form').trigger('change'));

    return it('prevents navigating away', () => expect(_.result(view, 'onLeaveMessage')).toBeTruthy());
  });


  describe('when the user already has a TrialRequest and is a teacher', function() {
    beforeEach(function(done) {
      spyOn(me, 'isTeacher').and.returnValue(true);
      _.last(view.trialRequests.fakeRequests).respondWith({
        status: 200,
        responseText: JSON.stringify([{
          _id: '1',
          properties: {
            firstName: 'First',
            lastName: 'Last'
          }
        }])
      });
      return _.defer(done);
    }); // Let SuperModel finish

    // TODO: re-enable when student and teacher areas are enforced
    return xit('redirects to /teachers/courses', function() {
      expect(application.router.navigate).toHaveBeenCalled();
      const args = application.router.navigate.calls.argsFor(0);
      return expect(args[0]).toBe('/teachers/courses');
    });
  });


  describe('when the user has role "student"', function() {
    beforeEach(function() {
      me.set('role', 'student');
      // TODO: is this next line right? Seems to try to construct a TrialRequest with `[]` as its attributes (and below as well)
      _.last(view.trialRequests.fakeRequests).respondWith({ status: 200, responseText: JSON.stringify('[]') });
      return view.render();
    });

    it('shows a warning that they will convert to a teacher account', () => expect(view.$('#conversion-warning').length).toBe(1));

//      TODO: Figure out how to test this
//    describe 'the warning', ->
//      it 'includes a learn more link which opens a modal with more info'

    return describe('submitting the form', function() {
      beforeEach(function() {
        const form = view.$('form');
        forms.objectToForm(form, successForm, {overwriteExisting: true});
        spyOn(view, 'openModalView');
        return form.submit();
      });

      return it('requires confirmation', function() {
        expect(view.trialRequest.fakeRequests.length).toBe(0);
        const confirmModal = view.openModalView.calls.argsFor(0)[0];
        confirmModal.trigger('confirm');
        const request = _.last(view.trialRequest.fakeRequests);
        expect(request.url).toBe('/db/trial.request');
        return expect(request.method).toBe('POST');
      });
    });
  });

  describe('"Log out" link', function() {
    beforeEach(() => _.last(view.trialRequests.fakeRequests).respondWith({ status: 200, responseText: JSON.stringify('[]') }));

    return it('logs out the user and redirects them to /teachers/signup', function() {
      spyOn(me, 'logout');
      view.$('#logout-link').click();
      return expect(me.logout).toHaveBeenCalled();
    });
  });

  describe('submitting the form', function() {
    beforeEach(function() {
      spyOn(me, 'unsubscribe');
      view.$el.find('#request-form').trigger('change'); // to confirm navigating away isn't prevented
      _.last(view.trialRequests.fakeRequests).respondWith({ status: 200, responseText: JSON.stringify('[]') });
      const form = view.$('form');
      forms.objectToForm(form, successForm, {overwriteExisting: true});
      return form.submit();
    });

    it('does not prevent navigating away', () => expect(_.result(view, 'onLeaveMessage')).toBeFalsy());

    it('creates a new TrialRequest with the information', function() {
      const request = _.last(view.trialRequest.fakeRequests);
      expect(request).toBeTruthy();
      expect(request.method).toBe('POST');
      const attrs = JSON.parse(request.params);
      expect(attrs.properties != null ? attrs.properties.firstName : undefined).toBe('Mr');
      expect(attrs.properties != null ? attrs.properties.siteOrigin : undefined).toBe('convert teacher');
      return expect(attrs.properties != null ? attrs.properties.email : undefined).toBe('some@email.com');
    });

    it('redirects to /teachers/classes', function() {
      const request = _.last(view.trialRequest.fakeRequests);
      request.respondWith({
        status: 201,
        responseText: JSON.stringify(_.extend({_id:'fraghlarghl'}, JSON.parse(request.params)))
      });
      expect(application.router.navigate).toHaveBeenCalled();
      const args = application.router.navigate.calls.argsFor(0);
      return expect(args[0]).toBe('/teachers/classes');
    });

    it('sets a teacher role', function() {
      const request = _.last(view.trialRequest.fakeRequests);
      request.respondWith({
        status: 201,
        responseText: JSON.stringify(_.extend({_id:'fraghlarghl'}, JSON.parse(request.params)))
      });
      return expect(me.get('role')).toBe(successForm.role.toLowerCase());
    });

    return it('unsubscribes user', function() {
      const request = _.last(view.trialRequest.fakeRequests);
      request.respondWith({
        status: 201,
        responseText: JSON.stringify(_.extend({_id:'fraghlarghl'}, JSON.parse(request.params)))
      });
      return expect(me.unsubscribe).toHaveBeenCalled();
    });
  });

  describe('submitting the form without school', function() {
    beforeEach(function() {
      view.$el.find('#request-form').trigger('change'); // to confirm navigating away isn't prevented
      const form = view.$('form');
      const formData = _.omit(successForm, ['organization']);
      forms.objectToForm(form, formData);
      return form.submit();
    });

    return it('submits a trial request, which does not include school setting', function() {
      const request = jasmine.Ajax.requests.mostRecent();
      expect(request.url).toBe('/db/trial.request');
      expect(request.method).toBe('POST');
      const attrs = JSON.parse(request.params);
      expect(attrs.properties != null ? attrs.properties.organization : undefined).toBeUndefined();
      return expect(attrs.properties != null ? attrs.properties.district : undefined).toEqual('District');
    });
  });

  describe('submitting the form without district', function() {
    beforeEach(function() {
      view.$el.find('#request-form').trigger('change'); // to confirm navigating away isn't prevented
      const form = view.$('form');
      const formData = _.omit(successForm, ['district']);
      forms.objectToForm(form, formData);
      return form.submit();
    });

    return it('displays a validation error on district and not school', function() {
      expect(view.$('#organization-control').closest('.form-group').hasClass('has-error')).toEqual(false);
      return expect(view.$('#district-control').closest('.form-group').hasClass('has-error')).toEqual(true);
    });
  });

  return describe('submitting the form district set to n/a', function() {
    beforeEach(function() {
      view.$el.find('#request-form').trigger('change'); // to confirm navigating away isn't prevented
      const form = view.$('form');
      const formData = _.omit(successForm, ['organization']);
      formData.district = 'N/A';
      forms.objectToForm(form, formData);
      return form.submit();
    });

    return it('submits a trial request, which does not include district setting', function() {
      expect(view.$('#organization-control').closest('.form-group').hasClass('has-error')).toEqual(false);
      expect(view.$('#district-control').closest('.form-group').hasClass('has-error')).toEqual(false);
      const request = jasmine.Ajax.requests.mostRecent();
      expect(request.url).toBe('/db/trial.request');
      expect(request.method).toBe('POST');
      const attrs = JSON.parse(request.params);
      return expect(attrs.properties != null ? attrs.properties.district : undefined).toBeUndefined();
    });
  });
});
