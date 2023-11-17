/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const EditStudentModal = require('views/teachers/EditStudentModal');
const User = require('models/User');
const factories = require('test/app/factories');

describe('EditStudentModal', function() {

  let user = null;
  let modal = null;
  const email = "test@example.com";
  const newPassword = "new password";

  describe('for a verified user', function() {
    beforeEach(function(done) {
      user = factories.makeUser({ email, emailVerified: true });
      const classroom = factories.makeClassroom();
      modal = new EditStudentModal({ user, classroom });
      const request = jasmine.Ajax.requests.mostRecent();
      request.respondWith({ status: 200, responseText: JSON.stringify(user) });
      jasmine.demoModal(modal);
      modal.render();
      return _.defer(done);
    });

    it("has a new password field", function() {
      if (modal.$('.new-password-input').length < 1) {
        return fail("Expected there to be a new password input field");
      }
    });

    return it("has a change password button", function() {
      if (modal.$('.change-password-btn').length < 1) {
        return fail("Expected there to be a Change Password button");
      }
    });
  });

  return describe('for an unverified user', function() {
    beforeEach(function(done) {
      user = factories.makeUser({ email , emailVerified: false });
      const classroom = factories.makeClassroom();
      modal = new EditStudentModal({ user, classroom });
      const request = jasmine.Ajax.requests.mostRecent();
      request.respondWith({ status: 200, responseText: JSON.stringify(user) });
      jasmine.demoModal(modal);
      modal.render();
      return _.defer(done);
    });

    it("has a new password field", function() {
      if (modal.$('.new-password-input').length < 1) {
        return fail("Expected there to be a new password input field");
      }
    });

    it("has a change password button", function() {
      if (modal.$('.change-password-btn').length < 1) {
        return fail("Expected there to be a Change Password button");
      }
    });

    return describe('when you click the button', function() {
      it('sends a request', function() {
        modal.$('.change-password-btn').click();
        const request = jasmine.Ajax.requests.mostRecent();
        return expect(request).toBeDefined();
      });

      return xit('updates the button', function() {
        const request1 = jasmine.Ajax.requests.mostRecent();
        if (!request1) { fail("Expected a request to be sent"); }
        modal.$('.new-password-input').val(newPassword).change().trigger('input');
        modal.$('.change-password-btn').click();
        const request2 = jasmine.Ajax.requests.mostRecent();
        expect(request1).not.toBe(request2);
        if (request1 != null) {
          request1.respondWith({ status: 200, responseText: JSON.stringify(user) });
        }
        return expect(modal.$('.change-password-btn [data-i18n]').data('i18n')).toEqual('teacher.changed');
      });
    });
  });
});
