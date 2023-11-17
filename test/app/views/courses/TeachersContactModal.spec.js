/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const TeachersContactModal = require('views/teachers/TeachersContactModal');
const TrialRequests = require('collections/TrialRequests');
const factories = require('test/app/factories');

describe('TeachersContactModal', function() {
  beforeEach(function(done) {
    this.modal = new TeachersContactModal();
    this.modal.render();
    const trialRequests = new TrialRequests([factories.makeTrialRequest()]);
    this.modal.trialRequests.fakeRequests[0].respondWith({ status: 200, responseText: trialRequests.stringify() });
    this.modal.supermodel.once('loaded-all', done);
    return jasmine.demoModal(this.modal);
  });

  it('shows an error when the name is empty and the form is submitted', function() {
    this.modal.$('input[name="name"]').val('');
    this.modal.$('form').submit();
    return expect(this.modal.$('input[name="name"]').closest('.form-group').hasClass('has-error')).toBe(true);
  });

  it('shows an error when the email is invalid and the form is submitted', function() {
    this.modal.$('input[name="email"]').val('not an email');
    this.modal.$('form').submit();
    return expect(this.modal.$('input[name="email"]').closest('.form-group').hasClass('has-error')).toBe(true);
  });

  it('shows an error when licensesNeeded is not > 0 and the form is submitted', function() {
    this.modal.$('input[name="licensesNeeded"]').val('');
    this.modal.$('form').submit();
    return expect(this.modal.$('input[name="licensesNeeded"]').closest('.form-group').hasClass('has-error')).toBe(true);
  });

  it('shows an error when the message is empty and the form is submitted', function() {
    this.modal.$('textarea[name="message"]').val('');
    this.modal.$('form').submit();
    return expect(this.modal.$('textarea[name="message"]').closest('.form-group').hasClass('has-error')).toBe(true);
  });

  return describe('submit form', function() {
    beforeEach(function() {
      this.modal.$('input[name="licensesNeeded"]').val(777);
      return this.modal.$('form').submit();
    });

    it('disables inputs', function() {
      return Array.from(this.modal.$('button, input, textarea')).map((el) =>
        expect($(el).is(':disabled')).toBe(true));
    });

    describe('failed contact', function() {
      beforeEach(function() {
        const request = jasmine.Ajax.requests.mostRecent();
        return request.respondWith({status: 500});
      });

      return it('shows an error', function() {
        return expect(this.modal.$('.alert-danger').length).toBe(1);
      });
    });

    return describe('successful contact', function() {
      beforeEach(function() {
        const request = jasmine.Ajax.requests.mostRecent();
        return request.respondWith({status: 200, responseText: '{}'});
      });

      it('shows a success message', function() {
        return expect(this.modal.$('.alert-success').length).toBe(1);
      });

      return it('disables the submit button', function() {
        return expect(this.modal.$('#submit-btn').is(':disabled')).toBe(true);
      });
    });
  });
});

