/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const RequestQuoteView = require('views/teachers/RequestQuoteView');
const forms = require('core/forms');

describe('RequestQuoteView', function() {

  let view = null;

  const successForm = {
    fullName: 'A B',
    lastName: 'B',
    email: 'C@D.com',
    phoneNumber: '555-555-5555',
    role: 'Teacher',
    organization: 'School',
    district: 'District',
    city: 'Springfield',
    state: 'AL',
    country: 'United States',
    numStudents: '1-10',
    numStudentsTotal: '10,000+'
  };

  const isSubmitRequest = r => _.string.startsWith(r.url, '/db/trial.request') && (r.method === 'POST');

  describe('when an anonymous user', function() {
    beforeEach(function(done) {
      me.clear();
      me.set('_id', '1234');
      me._revertAttributes = {};
      spyOn(me, 'isAnonymous').and.returnValue(true);
      view = new RequestQuoteView();
      view.render();
      jasmine.demoEl(view.$el);
      return _.defer(done);
    }); // Let SuperModel finish

    describe('has an existing trial request', function() {
      beforeEach(function(done) {
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
        return view.supermodel.once('loaded-all', done);
      });

      return it('shows request received', function() {
        expect(view.$('#request-form').hasClass('hide')).toBe(true);
        return expect(view.$('#form-submit-success').hasClass('hide')).toBe(false);
      });
    });

    describe('does NOT have an existing trial request', function() {
      beforeEach(function(done) {
        const request = jasmine.Ajax.requests.mostRecent();
        request.respondWith({
          status: 200,
          responseText: '[]'
        });
        return _.defer(done);
      }); // Let SuperModel finish

      describe('when the form is unchanged', () => it('does not prevent navigating away', () => expect(_.result(view, 'onLeaveMessage')).toBeFalsy()));

      describe('when the form has changed but is not submitted', function() {
        beforeEach(() => view.$el.find('#request-form').trigger('change'));

        return it('prevents navigating away', () => expect(_.result(view, 'onLeaveMessage')).toBeTruthy());
      });

      return describe('on successful form submit', function() {
        beforeEach(function() {
          view.$el.find('#request-form').trigger('change'); // to confirm navigating away isn't prevented
          forms.objectToForm(view.$el, successForm);
          view.$('#request-form').submit();
          this.submitRequest = _.last(jasmine.Ajax.requests.filter(isSubmitRequest));
          return this.submitRequest.respondWith({
            status: 201,
            responseText: JSON.stringify(_.extend({_id: 'a'}, successForm))
          });
        });

        it('does not prevent navigating away', () => expect(_.result(view, 'onLeaveMessage')).toBeFalsy());

        it('creates a new trial request', function() {
          expect(this.submitRequest).toBeTruthy();
          expect(this.submitRequest.method).toBe('POST');
          const attrs = JSON.parse(this.submitRequest.params);
          return expect(attrs.properties != null ? attrs.properties.siteOrigin : undefined).toBe('demo request');
        });

        it('sets the user\'s role to the one they chose', function() {
          const request = _.last(jasmine.Ajax.requests.filter(r => _.string.startsWith(r.url, '/db/user')));
          expect(request).toBeTruthy();
          expect(request.method).toBe('PUT');
          return expect(JSON.parse(request.params).role).toBe('teacher');
        });

        it('shows a signup form', function() {
          expect(view.$('#form-submit-success').hasClass('hide')).toBe(false);
          return expect(view.$('#request-form').hasClass('hide')).toBe(true);
        });

        return describe('signup form', function() {
          beforeEach(function() {
            if (window.features.chinaUx) { return; }
            application.facebookHandler.fakeAPI();
            return application.gplusHandler.fakeAPI();
          });

          it('fills the username field with the given first and last names', () => expect(view.$('input[name="name"]').val()).toBe('A B'));

          it('includes a facebook button which will sign them in immediately', function() {
            if (window.features.chinUx) { return pending(); }
            view.$('#facebook-signup-btn').click();
            const request = jasmine.Ajax.requests.mostRecent();
            expect(request.method).toBe('PUT');
            return expect(request.url).toBe('/db/user?facebookID=abcd&facebookAccessToken=1234');
          });

          xit('includes a gplus button which will sign them in immediately', function() {
            if (window.features.chinaUx) { return pending(); }
            view.$('#gplus-signup-btn').click();
            const request = jasmine.Ajax.requests.mostRecent();
            expect(request.method).toBe('PUT');
            return expect(request.url).toBe('/db/user?gplusID=abcd&gplusAccessToken=1234');
          });

          return it('can sign them up with username and password', function() {
            const form = view.$('#signup-form');
            forms.objectToForm(form, {
              password1: 'asdf',
              password2: 'asdf',
              name: 'some name'
            });
            form.submit();
            const request = jasmine.Ajax.requests.mostRecent();
            expect(request.method).toBe('PUT');
            return expect(request.url).toBe('/db/user/1234');
          });
        });
      });
    });

    describe('tries to submit a request with an existing user\'s email', function() {
      beforeEach(function() {
        forms.objectToForm(view.$el, successForm);
        view.$('#request-form').submit();
        this.submitRequest = _.last(jasmine.Ajax.requests.filter(isSubmitRequest));
        return this.submitRequest.respondWith({
          status: 409,
          responseText: '{}'
        });
      });

      return it('shows an error that the email already exists', function() {
        expect(view.$('#email-form-group').hasClass('has-error')).toBe(true);
        return expect(view.$('#email-form-group .error-help-block').length).toBe(1);
      });
    });

    describe('does not submit the form without school', function() {
      beforeEach(function() {
        view.$el.find('#request-form').trigger('change'); // to confirm navigating away isn't prevented
        const form = view.$('#request-form');
        const formData = _.omit(successForm, ['organization']);
        forms.objectToForm(form, formData);
        return form.submit();
      });

      return it('does not submit form when school is not present', () => expect(view.$('#organization-control').closest('.form-group').hasClass('has-error')).toEqual(true));
    });

    describe('submits the form without district', function() {
      beforeEach(function() {
        view.$el.find('#request-form').trigger('change'); // to confirm navigating away isn't prevented
        const form = view.$('#request-form');
        const formData = _.omit(successForm, ['district']);
        forms.objectToForm(form, formData);
        return form.submit();
      });

      return it('displays a validation error on district and not school', function() {
        expect(view.$('#organization-control').closest('.form-group').hasClass('has-error')).toEqual(false);
        return expect(view.$('#district-control').closest('.form-group').hasClass('has-error')).toEqual(true);
      });
    });

    return describe('submits form with district set to n/a', function() {
      beforeEach(function() {
        view.$el.find('#request-form').trigger('change'); // to confirm navigating away isn't prevented
        const form = view.$('#request-form');
        const formData = _.clone(successForm);
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

  return describe('when a signed in user', function() {
    beforeEach(function(done) {
      me.clear();
      me.set('_id', '1234');
      me._revertAttributes = {};
      spyOn(me, 'isAnonymous').and.returnValue(false);
      view = new RequestQuoteView();
      view.render();
      jasmine.demoEl(view.$el);
      return _.defer(done);
    }); // Let SuperModel finish

    describe('has an existing trial request', function() {
      beforeEach(function(done) {
        const request = jasmine.Ajax.requests.mostRecent();
        request.respondWith({
          status: 200,
          responseText: JSON.stringify([{
            _id: '1',
            properties: {
              fullName: 'First Last',
              firstName: 'First',
              lastName: 'Last'
            }
          }])
        });
        return view.supermodel.once('loaded-all', done);
      });

      return it('shows form with data from the most recent request', () => expect(view.$('input[name="fullName"]').val()).toBe('First Last'));
    });

    return describe('has role "student"', function() {
      beforeEach(function(done) {
        me.clear();
        me.set('role', 'student');
        me.set('name', 'Some User');
        const request = jasmine.Ajax.requests.mostRecent();
        request.respondWith({ status: 200, responseText: '[]'});
        return _.defer(done);
      }); // Let SuperModel finish

      it('shows a conversion warning', () => expect(view.$('#conversion-warning').length).toBe(1));

      return it('requires confirmation to submit the form', function() {
        const form = view.$('#request-form');
        forms.objectToForm(form, successForm);
        spyOn(view, 'openModalView');
        form.submit();
        expect(view.openModalView).toHaveBeenCalled();

        let submitRequest = _.last(jasmine.Ajax.requests.filter(isSubmitRequest));
        expect(submitRequest).toBeFalsy();
        const confirmModal = view.openModalView.calls.argsFor(0)[0];
        confirmModal.trigger('confirm');
        submitRequest = _.last(jasmine.Ajax.requests.filter(isSubmitRequest));
        return expect(submitRequest).toBeTruthy();
      });
    });
  });
});
