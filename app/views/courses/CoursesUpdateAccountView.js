// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CoursesUpdateAccountView;
require('app/styles/courses/courses-update-account-view.sass');
const errors = require('core/errors');
const RootView = require('views/core/RootView');
const template = require('app/templates/courses/courses-update-account-view');
const AuthModal = require('views/core/AuthModal');
const JoinClassModal = require('views/courses/JoinClassModal');
const {logoutUser, me} = require('core/auth');
const utils = require('core/utils');

module.exports = (CoursesUpdateAccountView = (function() {
  CoursesUpdateAccountView = class CoursesUpdateAccountView extends RootView {
    static initClass() {
      this.prototype.id = 'courses-update-account-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click .login-btn': 'onClickLogInButton',
        'click .logout-btn': 'onClickLogoutButton',
        'click .remain-teacher-btn': 'onClickRemainTeacherButton',
        'click .update-teacher-btn': 'onClickUpdateTeacherButton',
        'click .remain-student-btn': 'onClickRemainStudentButton',
        'click .update-student-btn': 'onClickUpdateStudentButton',
        'click .remain-individual-btn': 'onClickRemainIndividualButton'
      };
    }

    initialize(options) {
      this.accountType = (() => { switch (false) {
        case !me.isTeacher(): return $.i18n.t('courses.teacher');
        case !me.isStudent(): return $.i18n.t('courses.student');
      } })();
      this.isOzaria = utils.isOzaria;
    }

    onClickLogInButton() {
      this.openModalView(new AuthModal());
      return (application.tracker != null ? application.tracker.trackEvent('Started Student Login', {category: 'Courses Update Account'}) : undefined);
    }

    onClickLogoutButton() {
      Backbone.Mediator.publish("auth:logging-out", {});
      return logoutUser();
    }

    onClickRemainTeacherButton(e) {
      return this.remainTeacher(e.target, 'Remain teacher');
    }

    onClickUpdateTeacherButton(e) {
      $(e.target).prop('disabled', true);
      if (application.tracker != null) {
        application.tracker.trackEvent('Update teacher', {category: 'Courses Update Account'});
      }
      return application.router.navigate('/teachers/update-account', {trigger: true});
    }

    onClickRemainStudentButton(e) {
      return this.becomeStudent(e.target, 'Remain student');
    }

    onClickUpdateStudentButton(e) {
      const joinClassModal = new JoinClassModal({ classCode: this.$('input[name="classCode"]').val() });
      this.openModalView(joinClassModal);
      return this.listenTo(joinClassModal, 'join:success', () => this.becomeStudent(e.target, 'Update student'));
    }
      // return unless window.confirm($.i18n.t('courses.update_account_confirm_update_student') + '\n\n' + $.i18n.t('courses.update_account_confirm_update_student2'))
      // @becomeStudent(e.target, 'Update student')

    onClickRemainIndividualButton(e) {
      return application.router.navigate('/', {trigger: true});
    }

    becomeStudent(targetElem, trackEventMsg) {
      $(targetElem).prop('disabled', true);
      return me.becomeStudent({
        success() {
          if (application.tracker != null) {
            application.tracker.trackEvent(trackEventMsg, {category: 'Courses Update Account'});
          }
          return application.router.navigate('/students', {trigger: true});
        },
        error() {
          $(targetElem).prop('disabled', false);
          return errors.showNotyNetworkError(...arguments);
        }
      });
    }

    remainTeacher(targetElem, trackEventMsg) {
      $(targetElem).prop('disabled', true);
      return me.remainTeacher({
        success() {
          if (application.tracker != null) {
            application.tracker.trackEvent(trackEventMsg, {category: 'Courses Update Account'});
          }
          return application.router.navigate('/teachers', {trigger: true});
        },
        error() {
          $(targetElem).prop('disabled', false);
          console.log(arguments);
          return errors.showNotyNetworkError(...arguments);
        }
      });
    }
  };
  CoursesUpdateAccountView.initClass();
  return CoursesUpdateAccountView;
})());
