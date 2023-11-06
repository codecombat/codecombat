// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ManageLicenseModal;
require('app/styles/courses/manage-license-modal.sass');
const ModalView = require('views/core/ModalView');
const State = require('models/State');
const template = require('templates/courses/manage-licenses-modal');
const Prepaids = require('collections/Prepaids');
const Prepaid = require('models/Prepaid');
const Classroom = require('models/Classroom');
const Classrooms = require('collections/Classrooms');
const User = require('models/User');
const Users = require('collections/Users');
const utils = require('core/utils');

module.exports = (ManageLicenseModal = (function() {
  ManageLicenseModal = class ManageLicenseModal extends ModalView {
    static initClass() {
      this.prototype.id = 'manage-license-modal';
      this.prototype.template = template;

      this.prototype.events = {
        'change input[type="checkbox"][name="user"]': 'updateSelectedStudents',
        'change .select-all-users-checkbox': 'toggleSelectAllStudents',
        'change .select-all-users-revoke-checkbox': 'toggleSelectAllStudentsRevoke',
        'change select.classroom-select': 'replaceStudentList',
        'submit form': 'onSubmitForm',
        'click #get-more-licenses-btn': 'onClickGetMoreLicensesButton',
        'click #selectPrepaidType .radio': 'onSelectPrepaidType',
        'click .change-tab': 'onChangeTab',
        'click .revoke-student-button': 'onClickRevokeStudentButton'
      };
    }

    getInitialState(options) {
      let selectedUserModels;
      const selectedUsers = options.selectedUsers || options.users;
      this.activeTab = options.tab != null ? options.tab : 'apply';
      if (this.activeTab === 'apply') {
        selectedUserModels = _.filter(selectedUsers.models, user => !user.isEnrolled());
      } else {
        selectedUserModels = selectedUsers.models;
      }
      return {
        selectedUsers: new Users(selectedUserModels),
        visibleSelectedUsers: new Users(selectedUserModels),
        error: null
      };
    }

    constructor (options) {
      super(options)
      this.state = new State(this.getInitialState(options));
      this.classroom = options.classroom;
      this.users = options.users.clone();
      this.users.comparator = user => user.broadName().toLowerCase();
      this.prepaids = new Prepaids();
      this.prepaids.comparator = 'endDate'; // use prepaids in order of expiration
      this.supermodel.trackRequest(this.prepaids.fetchForClassroom(this.classroom)); // do we need this or just passing prepaids from parent view?
      this.classrooms = new Classrooms();
      this.selectedPrepaidType = null;
      this.prepaidByGroup = {};
      this.teacherPrepaidIds = [];
      this.utils = utils;
      this.supermodel.trackRequest(this.classrooms.fetchMine({
        data: {archived: false},
        success: () => {
          return this.classrooms.each(classroom => {
            classroom.users = new Users();
            const jqxhrs = classroom.users.fetchForClassroom(classroom, { removeDeleted: true });
            return this.supermodel.trackRequests(jqxhrs);
          });
        }
        })
      );

      this.listenTo(this.state, 'change', function() {
        return this.renderSelectors('#submit-form-area');
      });
      this.listenTo(this.state.get('selectedUsers'), 'change add remove reset', function() {
        this.updateVisibleSelectedUsers();
        return this.renderSelectors('#submit-form-area');
      });
      this.listenTo(this.users, 'change add remove reset', function() {
        this.updateVisibleSelectedUsers();
        return this.render();
      });
      this.listenTo(this.prepaids, 'sync add remove reset', function() {
        this.prepaidByGroup = {};
        return this.prepaids.each(prepaid => {
          this.teacherPrepaidIds.push(prepaid.get('_id'));
          const type = prepaid.typeDescriptionWithTime();
          this.prepaidByGroup[type] = (this.prepaidByGroup != null ? this.prepaidByGroup[type] : undefined) || {num: 0, prepaid};
          return this.prepaidByGroup[type].num += (prepaid.get('maxRedeemers') || 0) - (_.size(prepaid.get('redeemers')) || 0);
        });
      });
    }

    onLoaded() {
      this.prepaids.reset(this.prepaids.filter(prepaid => prepaid.status() === 'available'));
      this.selectedPrepaidType = Object.keys(this.prepaidByGroup)[0];
      if(this.users.length) {
         this.selectedUser = this.users.models[0].id;
       }
      return super.onLoaded();
    }

    afterRender() {
      return super.afterRender();
    }
      // @updateSelectedStudents() # TODO: refactor to event/state style

    updateSelectedStudents(e) {
      const userID = $(e.currentTarget).data('user-id');
      const user = this.users.get(userID);
      if (this.state.get('selectedUsers').findWhere({ _id: user.id })) {
        this.state.get('selectedUsers').remove(user.id);
      } else {
        this.state.get('selectedUsers').add(user);
      }
      this.$(".select-all-users-checkbox").prop('checked', this.areAllSelected());
      return this.$(".select-all-users-revoke-checkbox").prop('checked', this.areAllSelectedRevoke());
    }
      // @render() # TODO: Have @state automatically listen to children's change events?

    studentsPrepaidsFromTeacher() {
      let allPrepaids = [];
      this.users.each(user => {
        const allPrepaidKeys = allPrepaids.map(p => p.prepaid);
        return allPrepaids = _.union(allPrepaids, _.uniq(user.activeProducts('course').filter(p => {
          return !Array.from(allPrepaidKeys).includes(p.prepaid) && _.contains(this.teacherPrepaidIds, p.prepaid);
        }), p => p.prepaid));
      });
      return allPrepaids.map(function(p) {
        const product = new Prepaid({
          includedCourseIDs: __guard__(p != null ? p.productOptions : undefined, x => x.includedCourseIDs),
          type: 'course'
        });
        return {id: p.prepaid, name: product.typeDescription()};
      });
    }

    enrolledUsers() {
      const prepaid = this.prepaidByGroup[this.selectedPrepaidType] != null ? this.prepaidByGroup[this.selectedPrepaidType].prepaid : undefined;
      if (!prepaid) { return []; }
      return this.users.filter(function(user) {
        const p = prepaid.numericalCourses();
        const s = p & user.prepaidNumericalCourses();
        return !(p ^ s);
      });
    }

    unenrolledUsers() {
      const prepaid = this.prepaidByGroup[this.selectedPrepaidType] != null ? this.prepaidByGroup[this.selectedPrepaidType].prepaid : undefined;
      if (!prepaid) { return []; }
      return this.users.filter(function(user) {
        const p = prepaid.numericalCourses();
        const s = p & user.prepaidNumericalCourses();
        return p ^ s;
      });
    }

    allUsers() { return this.users.toJSON(); }

    areAllSelected() {
      return _.all(this.unenrolledUsers(), user => this.state.get('selectedUsers').get(user.id));
    }

    areAllSelectedRevoke() {
      return _.all(this.allUsers(), user => {
        return this.state.get('selectedUsers').get(user._id);
      });
    }

    toggleSelectAllStudents(e) {
      if (this.areAllSelected()) {
        return this.unenrolledUsers().forEach((user, index) => {
          if (this.state.get('selectedUsers').findWhere({ _id: user.id })) {
            this.$(`[type='checkbox'][data-user-id='${user.id}']`).prop('checked', false);
            return this.state.get('selectedUsers').remove(user.id);
          }
        });
      } else {
        return this.unenrolledUsers().forEach((user, index) => {
          if (!this.state.get('selectedUsers').findWhere({ _id: user.id })) {
            this.$(`[type='checkbox'][data-user-id='${user.id}']`).prop('checked', true);
            return this.state.get('selectedUsers').add(user);
          }
        });
      }
    }

    toggleSelectAllStudentsRevoke(e) {
      if (this.areAllSelectedRevoke()) {
        return this.users.forEach((user, index) => {
          if (this.state.get('selectedUsers').findWhere({ _id: user.id })) {
            this.$(`[type='checkbox'][data-user-id='${user.id}']`).prop('checked', false);
            return this.state.get('selectedUsers').remove(user.id);
          }
        });
      } else {
        return this.users.forEach((user, index) => {
          if (!this.state.get('selectedUsers').findWhere({ _id: user.id })) {
            this.$(`[type='checkbox'][data-user-id='${user.id}']`).prop('checked', true);
            return this.state.get('selectedUsers').add(user);
          }
        });
      }
    }

    replaceStudentList(e) {
      let users;
      const selectedClassroomID = $(e.currentTarget).val();
      this.classroom = this.classrooms.get(selectedClassroomID);
      if (!this.classroom) {
        users = _.uniq(_.flatten(this.classrooms.map(classroom => classroom.users.models)));
        this.users.reset(users);
        this.users.sort();
      } else {
        this.users.reset(this.classrooms.get(selectedClassroomID).users.models);
      }
      this.render();
      return null;
    }

    onSubmitForm(e) {
      e.preventDefault();
      this.state.set({error: null});
      const usersToRedeem = this.state.get('visibleSelectedUsers');
      return this.redeemUsers(usersToRedeem);
    }

    updateVisibleSelectedUsers() {
      return this.state.set({ visibleSelectedUsers: new Users(this.state.get('selectedUsers').filter(u => this.users.get(u))) });
    }

    redeemUsers(usersToRedeem) {
      if (!usersToRedeem.size()) {
        this.finishRedeemUsers();
        this.hide();
        return;
      }

      const user = usersToRedeem.first();
      const prepaid = this.prepaids.find(prepaid => (prepaid.status() === 'available') && (prepaid.typeDescriptionWithTime() === this.selectedPrepaidType));
      const options = {
        success: prepaid => {
          let left;
          const userProducts = (left = user.get('products')) != null ? left : [];
          user.set('products', userProducts.concat(prepaid.convertToProduct()));
          usersToRedeem.remove(user);
          this.state.get('selectedUsers').remove(user);
          this.updateVisibleSelectedUsers();
          // pct = 100 * (usersToRedeem.originalSize - usersToRedeem.size() / usersToRedeem.originalSize)
          // @$('#progress-area .progress-bar').css('width', "#{pct.toFixed(1)}%")
          if (application.tracker != null) {
            application.tracker.trackEvent('Enroll modal finished enroll student', {category: 'Courses', userID: user.id});
          }
          return this.redeemUsers(usersToRedeem);
        },
        error: (prepaid, jqxhr) => {
          return this.state.set({ error: jqxhr.responseJSON.message });
        }
      };
      if (!this.classroom.isOwner() && this.classroom.hasWritePermission()) {
        options.data = { sharedClassroomId: this.classroom.id };
      }
      prepaid.redeem(user, options);
      return (window.tracker != null ? window.tracker.trackEvent("Teachers Class Enrollment Enroll Student", {category: 'Teachers', classroomID: this.classroom.id, userID: user.id}) : undefined);
    }

    finishRedeemUsers() {
      return this.trigger('redeem-users', this.state.get('selectedUsers'));
    }

    onSelectPrepaidType(e) {
      this.selectedPrepaidType = $(e.target).parent().children('input').val();
      this.state.set({
        unusedEnrollments: (this.prepaidByGroup[this.selectedPrepaidType] != null ? this.prepaidByGroup[this.selectedPrepaidType].num : undefined)
      });
      return this.renderSelectors("#apply-page");
    }

    onClickGetMoreLicensesButton() {
      return (typeof this.hide === 'function' ? this.hide() : undefined); // In case this is opened in /teachers/licenses itself, otherwise the button does nothing
    }

    onChangeTab(e) {
      this.activeTab = $(e.target).data('tab');
      this.renderSelectors('.modal-body-content');
      return this.renderSelectors('#tab-nav');
    }

    onClickRevokeStudentButton(e) {
      const button = $(e.currentTarget);
      const prepaidId = button.data('prepaid-id');

      const usersToRedeem = this.state.get('visibleSelectedUsers');
      if (!usersToRedeem.size()) { return alert($.i18n.t('teacher.revoke_alert_no_student')); }
      const s = $.i18n.t('teacher.revoke_selected_confirm');
      if (!confirm(s)) { return; }
      button.text($.i18n.t('teacher.revoking'));
      return this.revokeUsers(usersToRedeem, prepaidId);
    }

    revokeUsers(usersToRedeem, prepaidId) {
      if (!usersToRedeem.size()) {
        this.finishRedeemUsers();
        this.hide();
        return;
      }

      const user = usersToRedeem.first();
      const prepaid = user.makeCoursePrepaid(prepaidId);
      if (!prepaid) { // in case teacher select extra students
        usersToRedeem.remove(user);
        this.state.get('selectedUsers').remove(user);
        this.updateVisibleSelectedUsers();
        this.revokeUsers(usersToRedeem, prepaidId);
      }

      const options = {
        success: () => {
          user.set('products', user.get('products').map(function(p) {
            if (p.prepaid === prepaidId) {
              p.endDate = new Date().toISOString();
            }
            return p;
          }));
          usersToRedeem.remove(user);
          this.state.get('selectedUsers').remove(user);
          this.updateVisibleSelectedUsers();
          if (application.tracker != null) {
            application.tracker.trackEvent('Revoke modal finished revoke student', {category: 'Courses', userID: user.id});
          }
          return this.revokeUsers(usersToRedeem, prepaidId);
        },
        error: (prepaid, jqxhr) => {
          return this.state.set({ error: jqxhr.responseJSON.message });
        }
      };
      if (!this.classroom.isOwner() && this.classroom.hasWritePermission()) {
        options.data = { sharedClassroomId: this.classroom.id };
      }
      return prepaid.revoke(user, options);
    }
  };
  ManageLicenseModal.initClass();
  return ManageLicenseModal;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}