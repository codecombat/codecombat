// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let EnrollmentsView;
require('app/styles/courses/enrollments-view.sass');
const RootView = require('views/core/RootView');
const Classrooms = require('collections/Classrooms');
const State = require('models/State');
const User = require('models/User');
const Prepaids = require('collections/Prepaids');
const template = require('app/templates/courses/enrollments-view');
const Users = require('collections/Users');
const Courses = require('collections/Courses');
const HowToEnrollModal = require('views/teachers/HowToEnrollModal');
const TeachersContactModal = require('views/teachers/TeachersContactModal');
const ActivateLicensesModal = require('views/courses/ActivateLicensesModal');
const utils = require('core/utils');
const ShareLicensesModal = require('views/teachers/ShareLicensesModal');

const {
  STARTER_LICENSE_COURSE_IDS,
  FREE_COURSE_IDS
} = require('core/constants');

module.exports = (EnrollmentsView = (function() {
  EnrollmentsView = class EnrollmentsView extends RootView {
    static initClass() {
      this.prototype.id = 'enrollments-view';
      this.prototype.template = template;
      this.prototype.enrollmentRequestSent = false;
  
      this.prototype.events = {
        'click #enroll-students-btn': 'onClickEnrollStudentsButton',
        'click #how-to-enroll-link': 'onClickHowToEnrollLink',
        'click #contact-us-btn': 'onClickContactUsButton',
        'click .share-licenses-link': 'onClickShareLicensesLink'
      };
    }

    getTitle() { return $.i18n.t('teacher.enrollments'); }

    i18nData() {
      return {starterLicenseCourseList: this.state.get('starterLicenseCourseList')};
    }

    initialize(options) {
      this.state = new State({
        totalEnrolled: 0,
        totalNotEnrolled: 0,
        classroomNotEnrolledMap: {},
        classroomEnrolledMap: {},
        numberOfStudents: 15,
        totalCourses: 0,
        prepaidGroups: {
          'available': [],
          'pending': []
        },
        shouldUpsell: false
      });
      if (window.tracker != null) {
        window.tracker.trackEvent('Classes Licenses Loaded', {category: 'Teachers'});
      }
      super.initialize(options);

      this.courses = new Courses();
      this.supermodel.trackRequest(this.courses.fetch({data: { project: 'free,i18n,name' }}));
      this.listenTo(this.courses, 'sync', function() {
        return this.state.set({ starterLicenseCourseList: this.getStarterLicenseCourseList() });
    });
      // Listen for language change
      this.listenTo(me, 'change:preferredLanguage', function() {
        return this.state.set({ starterLicenseCourseList: this.getStarterLicenseCourseList() });
    });
      this.members = new Users();
      this.classrooms = new Classrooms();
      this.classrooms.comparator = '_id';
      this.listenToOnce(this.classrooms, 'sync', this.onceClassroomsSync);
      this.supermodel.trackRequest(this.classrooms.fetchMine());
      this.prepaids = new Prepaids();
      this.supermodel.trackRequest(this.prepaids.fetchMineAndShared());
      this.listenTo(this.prepaids, 'sync', this.onPrepaidsSync);
      this.debouncedRender = _.debounce(this.render, 0);
      this.listenTo(this.prepaids, 'sync', this.updatePrepaidGroups);
      this.listenTo(this.state, 'all', this.debouncedRender);

      __guard__(me.getClientCreatorPermissions(), x => x.then(() => (typeof this.render === 'function' ? this.render() : undefined)));

      const leadPriorityRequest = me.getLeadPriority();
      this.supermodel.trackRequest(leadPriorityRequest);
      return leadPriorityRequest.then(r => this.onLeadPriorityResponse(r));
    }

    getStarterLicenseCourseList() {
      if (!this.courses.loaded) { return; }
      const COURSE_IDS = _.difference(STARTER_LICENSE_COURSE_IDS, FREE_COURSE_IDS);
      const starterLicenseCourseList = _.difference(STARTER_LICENSE_COURSE_IDS, FREE_COURSE_IDS).map(_id => {
        return utils.i18n(__guard__(this.courses.findWhere({_id}), x => x.attributes) || {}, 'name');
      });
      starterLicenseCourseList.push($.i18n.t('general.and') + ' ' + starterLicenseCourseList.pop());
      return starterLicenseCourseList.join(', ');
    }

    onceClassroomsSync() {
      return Array.from(this.classrooms.models).map((classroom) =>
        this.supermodel.trackRequests(this.members.fetchForClassroom(classroom, {remove: false, removeDeleted: true})));
    }

    onLoaded() {
      this.calculateEnrollmentStats();
      this.state.set('totalCourses', this.courses.size());
      return super.onLoaded();
    }

    onPrepaidsSync() {
      this.prepaids.each(prepaid => {
        prepaid.creator = new User();
        // We never need this information if the user would be `me`
        if (prepaid.get('creator') !== me.id) {
          return this.supermodel.trackRequest(prepaid.creator.fetchCreatorOfPrepaid(prepaid));
        }
      });

      return this.decideUpsell();
    }

    onLeadPriorityResponse({ priority }) {
      this.state.set({ leadPriority: priority });
      return this.decideUpsell();
    }

    decideUpsell() {
      // There are also non classroom prepaids.  We only use the course or starter_license prepaids to determine
      // if we should skip upsell (we ignore the others).

      const coursePrepaids = this.prepaids.filter(p => p.get('type') === 'course');

      const skipUpsellDueToExistingLicenses = coursePrepaids.length > 0;
      const shouldUpsell = !skipUpsellDueToExistingLicenses && (this.state.get('leadPriority') === 'low') && (me.get('preferredLanguage') !== 'nl-BE');

      this.state.set({ shouldUpsell });

      if (shouldUpsell && !this.upsellTracked) {
        this.upsellTracked = true;
        return (application.tracker != null ? application.tracker.trackEvent('Starter License Upsell: Banner Viewed', {price: this.state.get('centsPerStudent'), seats: this.state.get('quantityToBuy')}) : undefined);
      }
    }

    updatePrepaidGroups() {
      return this.state.set('prepaidGroups', this.prepaids.groupBy(p => p.status()));
    }

    calculateEnrollmentStats() {
      this.removeDeletedStudents();

      // sort users into enrolled, not enrolled
      const groups = this.members.groupBy(m => m.isEnrolled());
      const enrolledUsers = new Users(groups.true);
      this.notEnrolledUsers = new Users(groups.false);

      const map = {};

      for (var classroom of Array.from(this.classrooms.models)) {
        map[classroom.id] = _.countBy(classroom.get('members'), userID => enrolledUsers.get(userID) != null).false;
      }

      this.state.set({
        totalEnrolled: enrolledUsers.size(),
        totalNotEnrolled: this.notEnrolledUsers.size(),
        classroomNotEnrolledMap: map
      });

      return true;
    }

    removeDeletedStudents(e) {
      for (var classroom of Array.from(this.classrooms.models)) {
        _.remove(classroom.get('members'), memberID => {
          return !this.members.get(memberID) || __guard__(this.members.get(memberID), x => x.get('deleted'));
        });
      }
      return true;
    }

    onClickHowToEnrollLink() {
      return this.openModalView(new HowToEnrollModal());
    }

    onClickContactUsButton() {
      if (window.tracker != null) {
        window.tracker.trackEvent('Classes Licenses Contact Us', {category: 'Teachers'});
      }
      const modal = new TeachersContactModal();
      this.openModalView(modal);
      return modal.on('submit', () => {
        this.enrollmentRequestSent = true;
        return this.debouncedRender();
      });
    }

    onClickEnrollStudentsButton() {
      if (window.tracker != null) {
        window.tracker.trackEvent('Classes Licenses Enroll Students', {category: 'Teachers'});
      }
      const modal = new ActivateLicensesModal({ selectedUsers: this.notEnrolledUsers, users: this.members });
      this.openModalView(modal);
      return modal.once('hidden', () => {
        this.prepaids.add(modal.prepaids.models, { merge: true });
        return this.debouncedRender();
      }); // Because one changed model does not a collection update make
    }

    onClickShareLicensesLink(e) {
      const prepaidID = $(e.currentTarget).data('prepaidId');
      this.shareLicensesModal = new ShareLicensesModal({prepaid: this.prepaids.get(prepaidID)});
      this.shareLicensesModal.on('setJoiners', (prepaidID, joiners) => {
        const prepaid = this.prepaids.get(prepaidID);
        return prepaid.set({ joiners });
      });
      return this.openModalView(this.shareLicensesModal);
    }
  };
  EnrollmentsView.initClass();
  return EnrollmentsView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}