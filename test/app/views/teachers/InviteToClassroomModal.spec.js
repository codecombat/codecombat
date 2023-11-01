/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const InviteToClassroomModal = require('views/courses/InviteToClassroomModal');
const User = require('models/User');
const factories = require('test/app/factories');

describe('InviteToClassroomModal', function() {

  let modal = null;

  beforeEach(function(done) {
    window.me = (this.teacher = factories.makeUser());
    this.classroom = factories.makeClassroom({ code: "wordsouphere", codeCamel: "WordSoupHere", ownerID: this.teacher.id });
    this.recaptchaResponseToken = '1234';
    modal = new InviteToClassroomModal({ classroom: this.classroom });
    modal.recaptchaResponseToken = this.recaptchaResponseToken;
    jasmine.demoModal(modal);
    modal.render();
    return _.defer(done);
  });

  return describe('Invite by email', function() {
    beforeEach(function(done) {
      this.emails = ['test@example.com', 'test2@example.com'];
      modal.$('#invite-emails-textarea').val(this.emails.join('\n'));
      modal.$('#send-invites-btn').click();
      return _.defer(done);
    });

    return it('sends the request', function(done) {
      const request = jasmine.Ajax.requests.mostRecent();
      expect(request.url).toBe(`/db/classroom/${this.classroom.id}/invite-members`);
      expect(request.method).toBe("POST");
      expect(request.data()['emails[]']).toEqual(this.emails);
      expect(request.data()['recaptchaResponseToken']).toEqual([this.recaptchaResponseToken]);
      return _.defer(done);
    });
  });
});
