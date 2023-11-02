/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AnonymousTeacherModal;
const ModalView = require('./ModalView');
const template = require('app/templates/core/anonymous-teacher-modal');
require('app/styles/modal/anonymous-teacher-modal.sass');
const CreateAccountModal = require('views/core/CreateAccountModal/CreateAccountModal');
const forms = require('core/forms');
const errors = require('core/errors');
const State = require('models/State');
const contact = require('core/contact');
const storage = require('core/storage');

module.exports = (AnonymousTeacherModal = (function() {
  AnonymousTeacherModal = class AnonymousTeacherModal extends ModalView {
    static initClass() {
      this.prototype.id = 'anonymous-teacher-modal';
      this.prototype.template = template;
      this.prototype.closeButton = true;
  
      this.prototype.events = {
        'click #anonymous-teacher-signup-button': 'onClickAnonymousTeacherSignupButton',
        'change #anonymous-teacher-email-input': 'onChangeAnonymousTeacherEmailInput',
        'input #anonymous-teacher-email-input': 'onChangeAnonymousTeacherEmailInput',
        'change #anonymous-teacher-student-name-input': 'onChangeAnonymousStudentNameInput',
        'input #anonymous-teacher-student-name-input': 'onChangeAnonymousStudentNameInput',
        'click #anonymous-teacher-email-send-button': 'onClickAnonymousTeacherEmailSendButton'
      };
    }

    initialize() {
      this.state = new State({
        checkEmailState: 'none',  // 'none', 'valid', 'invalid'
        checkNameState: 'none',  // 'none', 'valid', 'invalid'
        sendEmailState: 'none'
      });  // 'none', 'sending', 'sent', 'error'
      if (storage.load('teacher signup email sent')) { this.state.set('sendEmailState', 'sent'); }
      this.listenTo(this.state, 'change:checkEmailState', function() { return this.renderSelectors('.email-check', '#anonymous-teacher-email-send-button'); });
      this.listenTo(this.state, 'change:checkNameState', function() { return this.renderSelectors('.name-check', '#anonymous-teacher-email-send-button'); });
      this.listenTo(this.state, 'change:sendEmailState', function() { return this.renderSelectors('#anonymous-teacher-email-send-button', '#anonymous-teacher-email-error'); });
      return (window.tracker != null ? window.tracker.trackEvent('Anonymous teacher signup modal opened', {category: 'World Map', sendEmailState: this.state.get('sendEmailState')}) : undefined);
    }

    onClickAnonymousTeacherSignupButton(e) {
      this.openModalView(new CreateAccountModal({startOnPath: 'teacher'}));
      return (window.tracker != null ? window.tracker.trackEvent('Anonymous teacher signup modal teacher signup', {category: 'World Map'}) : undefined);
    }

    getEmail() { return _.string.trim(this.$('#anonymous-teacher-email-input').val()); }

    getStudentName() { return _.string.trim(this.$('#anonymous-teacher-student-name-input').val()); }

    onChangeAnonymousTeacherEmailInput(e) {
      const email = this.getEmail();
      const valid = forms.validateEmail(email) && !/codecombat/i.test(email);
      if (!email) {
        return this.state.set('checkEmailState', 'none');
      } else if (valid) {
        return this.state.set('checkEmailState', 'valid');
      } else {
        return this.state.set('checkEmailState', 'invalid');
      }
    }

    onChangeAnonymousStudentNameInput(e) {
      const name = this.getStudentName();
      if (!name) {
        return this.state.set('checkNameState', 'none');
      } else if (!_.isEmpty(name)) {
        return this.state.set('checkNameState', 'valid');
      } else {
        return this.state.set('checkNameState', 'invalid');
      }
    }

    onClickAnonymousTeacherEmailSendButton(e) {
      if (this.state.get('sendEmailState' === 'sent')) { return; }
      this.state.set('sendEmailState', 'sending');
      return contact.sendTeacherSignupInstructions(this.getEmail(), this.getStudentName())
        .then(() => {
          this.state.set('sendEmailState', 'sent');
          storage.save('teacher signup email sent', true);
          if (window.tracker != null) {
            window.tracker.trackEvent('Anonymous teacher signup modal sent', {category: 'World Map', email: this.getEmail(), name: this.getStudentName()});
          }
          return this.hide();
      }).catch(() => {
          return this.state.set('sendEmailState', 'error');
      });
    }
  };
  AnonymousTeacherModal.initClass();
  return AnonymousTeacherModal;
})());
