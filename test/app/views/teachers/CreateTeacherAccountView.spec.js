/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const CreateTeacherAccountView = require('views/teachers/CreateTeacherAccountView');
const forms = require('core/forms');

describe('/teachers/signup', function() {

  describe('when logged out', () => it('displays CreateTeacherAccountView', function() {
    spyOn(me, 'isAnonymous').and.returnValue(true);
    spyOn(application.router, 'routeDirectly');
    Backbone.history.loadUrl('/teachers/signup');
    expect(application.router.routeDirectly.calls.count()).toBe(1);
    const args = application.router.routeDirectly.calls.argsFor(0);
    return expect(args[0]).toBe('teachers/CreateTeacherAccountView');
  }));

  return describe('when logged in', () => it('redirects to /teachers/update-account', function() {
    spyOn(me, 'isAnonymous').and.returnValue(false);
    spyOn(application.router, 'navigate');
    Backbone.history.loadUrl('/teachers/signup');
    expect(application.router.navigate.calls.count()).toBe(1);
    const args = application.router.navigate.calls.argsFor(0);
    return expect(args[0]).toBe('/teachers/update-account');
  }));
});

describe('CreateTeacherAccountView', function() {

  let view = null;

  const successForm = {
    name: 'New Name',
    phoneNumber: '555-555-5555',
    role: 'Teacher',
    organization: 'School',
    district: 'District',
    city: 'Springfield',
    state: 'AL',
    country: 'United States',
    numStudents: '1-10',
    numStudentsTotal: '1-500',
    educationLevel: ['Middle'],
    email: 'some@email.com',
    firstName: 'Mr',
    lastName: 'Bean',
    password1: 'letmein',
    password2: 'letmein'
  };

  beforeEach(function(done) {
    me.clear();
    me.set('_id', '1234');
    me._revertAttributes = {};
    spyOn(me, 'isAnonymous').and.returnValue(true);
    view = new CreateTeacherAccountView();
    view.render();
    jasmine.demoEl(view.$el);

    const request = jasmine.Ajax.requests.mostRecent();
    request.respondWith({
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

  describe('when the form is unchanged', () => it('does not prevent navigating away', () => expect(_.result(view, 'onLeaveMessage')).toBeFalsy()));

  describe('when the form has changed but is not submitted', function() {
    beforeEach(() => view.$el.find('form').trigger('change'));

    return it('prevents navigating away', () => expect(_.result(view, 'onLeaveMessage')).toBeTruthy());
  });

  describe('"Log in" link', () => it('opens the log in modal', function() {
    spyOn(view, 'openModalView');
    view.$('.alert .login-link').click();
    expect(view.openModalView.calls.count()).toBe(1);
    const AuthModal = require('views/core/AuthModal');
    return expect(view.openModalView.calls.argsFor(0)[0] instanceof AuthModal).toBe(true);
  }));

  if (!window.features.chinaUx) {
    describe('clicking the Facebook button', function() {

      beforeEach(function() {
        application.facebookHandler.fakeAPI();
        view.$('#facebook-signup-btn').click();
        const request = jasmine.Ajax.requests.mostRecent();
        expect(request.url).toBe('/db/user?facebookID=abcd&facebookAccessToken=1234');
        return expect(request.method).toBe('GET');
      });

      describe('when an associated user already exists', function() {
        beforeEach(function() {
          const request = jasmine.Ajax.requests.mostRecent();
          return request.respondWith({
            status: 200,
            responseText: JSON.stringify({_id: 'abcd'})
          });
        });

        return it('logs them in and redirects them to the ConvertToTeacherAccountView', function() {
          const request = jasmine.Ajax.requests.mostRecent();
          return expect(request.url).toBe('/auth/login-facebook');
        });
      });

      return describe('when the user connects with Facebook and there isn\'t already an associated account', function() {
        beforeEach(function() {
          const request = jasmine.Ajax.requests.mostRecent();
          return request.respondWith({ status: 404, responseText: '{}' });
        });

        it('disables and fills in the email, first name, last name and password fields', () => ['email', 'firstName', 'lastName', 'password1', 'password2'].map((field) =>
          expect(view.$(`input[name='${field}']`).attr('disabled')).toBeTruthy()));

        it('hides the social login buttons and shows a success message', function() {
          expect(view.$('#facebook-logged-in-row').hasClass('hide')).toBe(false);
          return expect(view.$('#social-network-signups').hasClass('hide')).toBe(true);
        });

        return describe('and the user finishes filling in the form and submits', function() {

          beforeEach(function() {
            const form = view.$('form');
            forms.objectToForm(form, successForm);
            return form.submit();
          });

          return it('creates a user associated with the Facebook account', function(done) {
            let request = jasmine.Ajax.requests.mostRecent();
            expect(request.url).toBe('/db/trial.request');
            request.respondWith({
              status: 201,
              responseText: JSON.stringify(_.extend({_id:'fraghlarghl'}, JSON.parse(request.params)))
            });
            return view.once('update-settings', () => {
              request = jasmine.Ajax.requests.mostRecent();
              expect(request.url).toBe("/db/user/1234");
              const body = JSON.parse(request.params);
              expect(body.firstName).toBe('Mr');
              expect(body.lastName).toBe('Bean');
              request.respondWith({
                status: 200,
                responseText: '{}'
              });
              return view.once('signup', () => {
                request = jasmine.Ajax.requests.mostRecent();
                expect(request.url).toBe("/db/user/1234/signup-with-facebook");
                const expected = {"name":"New Name","email":"some@email.com","facebookID":"abcd","facebookAccessToken":"1234"};
                const actual = JSON.parse(request.params);
                expect(_.isEqual(expected, actual)).toBe(true);
                return done();
              });
            });
          });
        });
      });
    });
  }

  if (false) {
    describe('clicking the G+ button', function() {

      beforeEach(function() {
        application.gplusHandler.fakeAPI();
        view.$('#gplus-signup-btn').click();
        const request = jasmine.Ajax.requests.mostRecent();
        expect(request.url).toBe('/db/user?gplusID=abcd&gplusAccessToken=1234&email=some%40email.com');
        return expect(request.method).toBe('GET');
      });

      describe('when an associated user already exists', function() {
        beforeEach(function() {
          const request = jasmine.Ajax.requests.mostRecent();
          return request.respondWith({
            status: 200,
            responseText: JSON.stringify({_id: 'abcd'})
          });
        });

        return it('logs them in and redirects them to the ConvertToTeacherAccountView', function() {
          const request = jasmine.Ajax.requests.mostRecent();
          return expect(request.url).toBe('/auth/login-gplus');
        });
      });

      return describe('when the user connects with G+ and there isn\'t already an associated account', function() {
        beforeEach(function() {
          const request = jasmine.Ajax.requests.mostRecent();
          return request.respondWith({ status: 404, responseText: '{}' });
        });

        it('disables and fills in the email, first name, last name and password fields', () => ['email', 'firstName', 'lastName', 'password1', 'password2'].map((field) =>
          expect(view.$(`input[name='${field}']`).attr('disabled')).toBeTruthy()));

        it('hides the social login buttons and shows a success message', function() {
          expect(view.$('#gplus-logged-in-row').hasClass('hide')).toBe(false);
          return expect(view.$('#social-network-signups').hasClass('hide')).toBe(true);
        });

        return describe('and the user finishes filling in the form and submits', function() {

          beforeEach(function() {
            const form = view.$('form');
            forms.objectToForm(form, successForm);
            return form.submit();
          });

          return it('creates a user associated with the GPlus account', function(done) {
            let request = jasmine.Ajax.requests.mostRecent();
            expect(request.url).toBe('/db/trial.request');
            request.respondWith({
              status: 201,
              responseText: JSON.stringify(_.extend({_id:'fraghlarghl'}, JSON.parse(request.params)))
            });
            return view.once('update-settings', () => {
              request = jasmine.Ajax.requests.mostRecent();
              expect(request.url).toBe("/db/user/1234");
              const body = JSON.parse(request.params);
              expect(body.firstName).toBe('Mr');
              expect(body.lastName).toBe('Bean');
              request.respondWith({
                status: 200,
                responseText: '{}'
              });
              return view.once('signup', () => {
                request = jasmine.Ajax.requests.mostRecent();
                expect(request.url).toBe("/db/user/1234/signup-with-gplus");
                const expected = {"name":"New Name","email":"some@email.com","gplusID":"abcd","gplusAccessToken":"1234"};
                const actual = JSON.parse(request.params);
                expect(_.isEqual(expected, actual)).toBe(true);
                return done();
              });
            });
          });
        });
      });
    });
  }

  describe('submitting the form successfully', function() {

    beforeEach(function() {
      view.$el.find('#request-form').trigger('change'); // to confirm navigating away isn't prevented
      const form = view.$('form');
      forms.objectToForm(form, successForm);
      return form.submit();
    });

    it('does not prevent navigating away', () => expect(_.result(view, 'onLeaveMessage')).toBeFalsy());

    it('submits a trial request, which does not include "account" settings', function() {
      const request = jasmine.Ajax.requests.mostRecent();
      expect(request.url).toBe('/db/trial.request');
      expect(request.method).toBe('POST');
      const attrs = JSON.parse(request.params);
      expect(attrs.password1).toBeUndefined();
      expect(attrs.password2).toBeUndefined();
      expect(attrs.name).toBeUndefined();
      expect(attrs.properties != null ? attrs.properties.siteOrigin : undefined).toBe('create teacher');
      expect(attrs.properties != null ? attrs.properties.organization : undefined).toEqual('School');
      return expect(attrs.properties != null ? attrs.properties.district : undefined).toEqual('District');
    });

    return describe('after saving the new trial request', function() {
      beforeEach(function(done) {
        view.once('update-settings', done);
        const request = jasmine.Ajax.requests.mostRecent();
        return request.respondWith({
          status: 201,
          responseText: JSON.stringify(_.extend({_id:'fraghlarghl'}, JSON.parse(request.params)))
        });
      });

      it('updates user and signs up with password', function(done) {
        let attr;
        let request = jasmine.Ajax.requests.mostRecent();
        expect(request.url).toBe('/db/user/1234');
        expect(request.method).toBe('PUT');
        const attrs = JSON.parse(request.params);
        for (attr of ['role', 'firstName', 'lastName']) {
          expect(attrs[attr]).toBeDefined();
        }
        request.respondWith({ status: 201, responseText: '{}' });
        return view.once('signup', () => {
          request = jasmine.Ajax.requests.mostRecent();
          expect(request.url).toBe('/db/user/1234/signup-with-password');
          const body = JSON.parse(request.params);
          for (attr of ['email', 'password', 'name']) {
            expect(body[attr]).toBeDefined();
          }
          return done();
        });
      });

      return describe('after saving the new user', function() {

        beforeEach(function(done) {
          spyOn(application.router, 'navigate');
          spyOn(application.router, 'reload');
          let request = jasmine.Ajax.requests.mostRecent();
          request.respondWith({
            status: 201,
            responseText: JSON.stringify(_.extend({_id:'fraghlarghl'}, JSON.parse(request.params)))
          });
          expect(request.url).toBe('/db/user/1234');
          return view.once('signup', () => {
            request = jasmine.Ajax.requests.mostRecent();
            expect(request.url).toBe('/db/user/1234/signup-with-password');
            request.respondWith({ status: 201, responseText: '{}' });
            return view.once('on-trial-request-submit-complete', done);
          });
        });

        return it('redirects to "/teachers/courses"', function() {
          expect(application.router.navigate).toHaveBeenCalled();
          return expect(application.router.reload).toHaveBeenCalled();
        });
      });
    });
  });


  describe('submitting the form with an email for an existing account', function() {

    beforeEach(function() {
      const form = view.$('form');
      forms.objectToForm(form, successForm);
      form.submit();
      const request = jasmine.Ajax.requests.mostRecent();
      return request.respondWith({ status: 409, responseText: '{}' });
    });

    return it('displays an error with a log in link', function() {
      expect(view.$('#email-form-group').hasClass('has-error')).toBe(true);
      spyOn(view, 'openModalView');
      view.$('#email-form-group .login-link').click();
      return expect(view.openModalView).toHaveBeenCalled();
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
