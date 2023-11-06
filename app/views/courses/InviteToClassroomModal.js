// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let InviteToClassroomModal;
require('app/styles/courses/invite-to-classroom-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/courses/invite-to-classroom-modal');

module.exports = (InviteToClassroomModal = (function() {
  InviteToClassroomModal = class InviteToClassroomModal extends ModalView {
    static initClass() {
      this.prototype.id = 'invite-to-classroom-modal';
      this.prototype.template = template;
      this.prototype.recaptcha_site_key = require('core/services/google').recaptcha_site_key;

      this.prototype.events = {
        'click #send-invites-btn': 'onClickSendInvitesButton',
        'click #copy-url-btn, #join-url-input': 'copyURL'
      };
    }

    initialize(options) {
      this.classroom = options.classroom;
      this.classCode = this.classroom.get('codeCamel') || this.classroom.get('code');
      this.joinURL = document.location.origin + "/students?_cc=" + this.classCode;
      window.recaptchaCallback = this.recaptchaCallback.bind(this);
    }

    onClickSendInvitesButton() {
      let emails = this.$('#invite-emails-textarea').val();
      emails = emails.split(/[,\n]/);
      emails = _.filter((Array.from(emails).map((email) => _.string.trim(email))));
      if (!emails.length) { return; }

      if (!this.recaptchaResponseToken) {
        $('#send-invites-btn').addClass('disabled');
        console.error('Tried to send student invites via email without recaptcha success token, resetting widget');
        if (typeof grecaptcha !== 'undefined' && grecaptcha !== null) {
          grecaptcha.reset();
        }
        return;
      }

      this.$('#send-invites-btn, #invite-emails-textarea, .g-recaptcha').addClass('hide');
      this.$('#invite-emails-sending-alert').removeClass('hide');
      if (application.tracker != null) {
        application.tracker.trackEvent('Classroom invite via email', {category: 'Courses', classroomID: this.classroom.id, emails});
      }
      return this.classroom.inviteMembers(emails, this.recaptchaResponseToken, {
        success: () => {
          this.$('#invite-emails-sending-alert').addClass('hide');
          return this.$('#invite-emails-success-alert').removeClass('hide');
        }
      });
    }

    copyURL() {
      this.$('#join-url-input').val(this.joinURL).select();
      try {
        document.execCommand('copy');
        this.$('#copied-alert').removeClass('hide');
        return (application.tracker != null ? application.tracker.trackEvent('Classroom copy URL', {category: 'Courses', classroomID: this.classroom.id, url: this.joinURL}) : undefined);
      } catch (err) {
        console.log('Oops, unable to copy', err);
        return this.$('#copy-failed-alert').removeClass('hide');
      }
    }

    recaptchaCallback(response) {
      this.$('#send-invites-btn').removeClass('disabled');
      return this.recaptchaResponseToken = response;
    }
  };
  InviteToClassroomModal.initClass();
  return InviteToClassroomModal;
})());
