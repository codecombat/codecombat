/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let EditStudentModal;
require('app/styles/teachers/edit-student-modal.sass');
const ModalView = require('views/core/ModalView');
const State = require('models/State');
const Prepaids = require('collections/Prepaids');
const template = require('app/templates/teachers/edit-student-modal');
const ManageLicenseModal = require('views/courses/ManageLicenseModal');
const Users = require('collections/Users');
const utils = require('core/utils');
const auth = require('core/auth');

module.exports = (EditStudentModal = (function() {
  EditStudentModal = class EditStudentModal extends ModalView {
    static initClass() {
      this.prototype.id = 'edit-student-modal';
      this.prototype.template = template;

      this.prototype.events = {
        'click .send-recovery-email-btn:not(.disabled)': 'onClickSendRecoveryEmail',
        'click .change-password-btn:not(.disabled)': 'onClickChangePassword',
        'click .revoke-student-btn': 'onClickRevokeStudentButton',
        'click .enroll-student-btn:not(.disabled)': 'onClickEnrollStudentButton',
        'input .new-password-input': 'onChangeNewPasswordInput'
      };
    }

    constructor ({ user, classroom, students }) {
      super(...arguments)
      this.user = user;
      this.classroom = classroom;
      this.students = students;
      this.supermodel.trackRequest(this.user.fetch());
      this.utils = require('core/utils');
      this.state = new State({
        emailSent: false,
        passwordChanged: false,
        newPassword: "",
        errorMessage: ""
      });
      this.fetchPrepaids();
      this.listenTo(this.state, 'change', this.render);
      this.listenTo(this.classroom, 'save-password:success', function() {
        this.state.set({ passwordChanged: true, errorMessage: "" });
      });
      this.listenTo(this.classroom, 'save-password:error', function(error) {
        if (error.message === "Data matches schema from \"not\"") {
          error.message = $.i18n.t('signup.invalid_password');
        }
        this.state.set({ errorMessage: error.message });
      });
        // TODO: Show an error. (password too short)

       __guard__(me.getClientCreatorPermissions(), x => x.then(() => (typeof this.render === 'function' ? this.render() : undefined)));
    }

    onLoaded() {
      this.prepaids.reset(this.prepaids.filter(prepaid => prepaid.status() === "available"));
      return super.onLoaded();
    }

    fetchPrepaids() {
      this.prepaids = new Prepaids();
      this.prepaids.comparator = 'endDate';
      if (utils.isOzaria) {
        return this.supermodel.trackRequest(this.prepaids.fetchMineAndShared());
      } else {
        return this.supermodel.trackRequest(this.prepaids.fetchForClassroom(this.classroom));
      }
    }

    onClickSendRecoveryEmail() {
      const email = this.user.get('email');
      return auth.sendRecoveryEmail(email).then(() => {
        return this.state.set({ emailSent: true });
    });
    }

    onClickRevokeStudentButton(e) {
      if (utils.isOzaria) {
        const button = $(e.currentTarget);
        const s = $.i18n.t('teacher.revoke_confirm').replace('{{student_name}}', this.user.broadName());
        if (!confirm(s)) { return; }
        const prepaid = this.user.makeCoursePrepaid();
        button.text($.i18n.t('teacher.revoking'));
        return prepaid.revoke(this.user, {
          success: () => {
            this.user.unset('coursePrepaid');
            return this.prepaids.fetchMineAndShared().done(() => this.render());
          },
          error: (prepaid, jqxhr) => {
            const msg = jqxhr.responseJSON.message;
            return noty({text: msg, layout: 'center', type: 'error', killer: true, timeout: 3000});
          }
        });
      } else { // CodeCombat
        if (me.id !== this.classroom.get('ownerID')) { return; }
        const selectedUsers = new Users([this.user]);
        const modal = new ManageLicenseModal({ classroom: this.classroom, selectedUsers , users: this.students, tab: 'revoke'});
        this.openModalView(modal);
        return modal.once('redeem-users', enrolledUsers => {
          enrolledUsers.each(newUser => {
            const user = this.students.get(newUser.id);
            if (user) {
              return user.set(newUser.attributes);
            }
          });
          return null;
        });
      }
    }

    studentStatusString() {
      const status = this.user.prepaidStatus();
      const expires = __guard__(this.user.get('coursePrepaid'), x => x.endDate);
      const date = (expires != null) ? moment(expires).utc().format('ll') : '';
      return utils.formatStudentLicenseStatusDate(status, date);
    }

    onClickEnrollStudentButton() {
      if (utils.isOzaria) {
        if (me.id !== this.classroom.get('ownerID')) { return; }
        const prepaid = this.prepaids.find(prepaid => prepaid.status() === 'available');
        prepaid.redeem(this.user, {
          success: prepaid => {
            return this.user.set('coursePrepaid', prepaid.pick('_id', 'startDate', 'endDate', 'type', 'includedCourseIDs'));
          },
          error: (prepaid, jqxhr) => {
            const msg = jqxhr.responseJSON.message;
            return noty({text: msg, layout: 'center', type: 'error', killer: true, timeout: 3000});
          },
          complete: () => {
            return this.render();
          }
        });
        return (window.tracker != null ? window.tracker.trackEvent("Teachers Class Enrollment Enroll Student", {category: 'Teachers', classroomID: this.classroom.id, userID: this.user.id}) : undefined);
      } else { // CodeCombat
        if (!this.classroom.hasWritePermission()) { return; }
        const selectedUsers = new Users([this.user]);
        const modal = new ManageLicenseModal({ classroom: this.classroom, selectedUsers , users: this.students });
        this.openModalView(modal);
        return modal.once('redeem-users', enrolledUsers => {
          enrolledUsers.each(newUser => {
            const user = this.students.get(newUser.id);
            if (user) {
              return user.set(newUser.attributes);
            }
          });
          return null;
        });
      }
    }

    onClickChangePassword() {
      return this.classroom.setStudentPassword(this.user, this.state.get('newPassword'));
    }

    onChangeNewPasswordInput(e) {
      this.state.set({
        newPassword: $(e.currentTarget).val(),
        emailSent: false,
        passwordChanged: false
      }, { silent: true });
      return this.renderSelectors('.change-password-btn');
    }
  };
  EditStudentModal.initClass();
  return EditStudentModal;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}