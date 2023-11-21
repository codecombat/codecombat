// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS204: Change includes calls to have a more natural evaluation order
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
const utils = require('core/utils');
const ShareLicensesModal = require('views/teachers/ShareLicensesModal');
const LicenseStatsModal = require('views/teachers/LicenseStatsModal');
const {sendSlackMessage} = require('core/contact');

const {
  STARTER_LICENSE_COURSE_IDS,
  FREE_COURSE_IDS
} = require('core/constants');

module.exports = (EnrollmentsView = (function() {
  EnrollmentsView = class EnrollmentsView extends RootView {
    static initClass () {
      this.prototype.id = 'enrollments-view';
      this.prototype.template = template;
      this.prototype.enrollmentRequestSent = false;

      this.prototype.events = {
        'click #how-to-enroll-link': 'onClickHowToEnrollLink',
        'click #contact-us-btn': 'onClickContactUsButton',
        'click .share-licenses-link': 'onClickShareLicensesLink',
        'click .license-stats': 'onClickLicenseStats'
      };
    }

    getTitle() { return $.i18n.t('teacher.enrollments'); }

    i18nData() {
      return {starterLicenseCourseList: this.state.get('starterLicenseCourseList')};
    }

    constructor (options) {
      super(options)
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
      if (window.tracker) {
        window.tracker.trackEvent('Classes Licenses Loaded', {category: 'Teachers'});
      }

      this.utils = utils;
      this.courses = new Courses();
      this.supermodel.trackRequest(this.courses.fetch({data: { project: 'free,i18n,name' }}));
      this.listenTo(this.courses, 'sync', function() {
        return this.state.set({ starterLicenseCourseList: this.getStarterLicenseCourseList() });
      })
      // Listen for language change
      this.listenTo(me, 'change:preferredLanguage', function () {
        return this.state.set({ starterLicenseCourseList: this.getStarterLicenseCourseList() });
      })
      this.members = new Users();
      this.classrooms = new Classrooms()
      this.classrooms.comparator = '_id';
      this.listenToOnce(this.classrooms, 'sync', this.onceClassroomsSync);
      this.supermodel.trackRequest(this.classrooms.fetchMine());
      this.prepaids = new Prepaids();
      this.supermodel.trackRequest(this.prepaids.fetchMineAndShared());
      this.listenTo(this.prepaids, 'sync', this.onPrepaidsSync);
      this.debouncedRender = _.debounce(this.render, 0);
      this.listenTo(this.prepaids, 'sync', this.updatePrepaidGroups);
      this.listenTo(this.state, 'all', this.debouncedRender);

      if (me.isSchoolAdmin()) {
        let left;
        this.newAdministeredClassrooms = new Classrooms();
        this.allAdministeredClassrooms = [];
        this.listenTo(this.newAdministeredClassrooms, 'sync', this.newAdministeredClassroomsSync);
        const teachers = (left = me.get('administratedTeachers')) != null ? left : [];
        this.totalAdministeredTeachers = teachers.length;
        teachers.forEach(teacher => {
          return this.supermodel.trackRequest(this.newAdministeredClassrooms.fetchByOwner(teacher));
        });
      }

      __guard__(me.getClientCreatorPermissions(), x => x.then(() => (typeof this.render === 'function' ? this.render() : undefined)));

      const leadPriorityRequest = me.getLeadPriority();
      this.supermodel.trackRequest(leadPriorityRequest);
      leadPriorityRequest.then(r => this.onLeadPriorityResponse(r))
    }

    afterRender() {
      super.afterRender();
      return this.$('[data-toggle="tooltip"]').tooltip({placement: 'top', html: true, animation: false, container: '#site-content-area'});
    }

    getStarterLicenseCourseList() {
      if (!this.courses.loaded) { return; }
      const COURSE_IDS = _.difference(STARTER_LICENSE_COURSE_IDS, FREE_COURSE_IDS);
      const starterLicenseCourseList = _.difference(STARTER_LICENSE_COURSE_IDS, FREE_COURSE_IDS).map(_id => {
        return utils.i18n(__guard__(this.courses.findWhere({_id}), x => x.attributes) || {}, 'name');
      });
      starterLicenseCourseList.push($.t('general.and') + ' ' + starterLicenseCourseList.pop());
      return starterLicenseCourseList.join(', ');
    }

    onceClassroomsSync() {
      return Array.from(this.classrooms.models).map((classroom) =>
        this.supermodel.trackRequests(this.members.fetchForClassroom(classroom, {remove: false, removeDeleted: true})));
    }

    newAdministeredClassroomsSync() {
      this.allAdministeredClassrooms.push(
        this.newAdministeredClassrooms
          .models
          .map(c => c.attributes)
          .filter(c => (c.courses.length > 1) || ((c.courses.length === 1) && (c.courses[0]._id !== utils.courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE)))
      );

      this.totalAdministeredTeachers -= 1;
      if (this.totalAdministeredTeachers === 0) {
        const students = this.uniqueStudentsPerYear(_.flatten(this.allAdministeredClassrooms));
        return this.state.set('uniqueStudentsPerYear', students);
      }
    }

    relativeToYear(momentDate) {
      let displayEndDate, displayStartDate;
      const year = momentDate.year();
      const shortYear = year - 2000;
      const start = `${year}-06-30`; // One day earlier to ease comparison
      const end = `${year + 1}-07-01`; // One day later to ease comparison
      if (moment(momentDate).isBetween(start, end)) {
        displayStartDate = `7/1/${shortYear}`;
        displayEndDate = `6/30/${year + 1}`;
      } else if (moment(momentDate).isBefore(start)) {
        displayStartDate = `7/1/${shortYear - 1}`;
        displayEndDate = `6/30/${year}`;
      } else if (moment(momentDate).isAfter(end)) {
        displayStartDate = `7/1/${shortYear + 1}`;
        displayEndDate = `6/30/${year + 2}`;
      }

      return $.i18n.t('school_administrator.date_thru_date', {
        startDateRange: displayStartDate,
        endDateRange: displayEndDate
      });
    }

    // Count total students in classrooms (both active and archived) created between
    // July 1-June 30 as the cut off for each school year (e.g. July 1, 2019-June 30, 2020)
    uniqueStudentsPerYear(allClassrooms) {
      const dateFromObjectId = objectId => new Date(parseInt(objectId.substring(0, 8), 16) * 1000);

      const years = {};
      for (var classroom of Array.from(allClassrooms)) {
        var { _id, members } = classroom;
        if ((members != null ? members.length : undefined) > 0) {
          var creationDate = moment(dateFromObjectId(_id));
          var year = this.relativeToYear(creationDate);
          if (!years[year]) {
            years[year] = new Set(members);
          } else {
            var yearSet = years[year];
            members.forEach(yearSet.add, yearSet);
          }
        }
      }

      return years;
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
      let needle, needle1, needle2;
      const coursePrepaids = this.prepaids.filter(p => p.get('type') === 'course');

      const skipUpsellDueToExistingLicenses = coursePrepaids.length > 0;
      const shouldUpsell = (me.useStripe() &&
        !skipUpsellDueToExistingLicenses &&
        (this.state.get('leadPriority') === 'low') &&
        ((needle = me.get('preferredLanguage'), !['nl-BE', 'nl-NL'].includes(needle))) &&
        ((needle1 = me.get('country'), !['australia', 'taiwan', 'hong-kong', 'netherlands', 'indonesia', 'singapore', 'malaysia'].includes(needle1))) &&
        !__guard__(me.get('administratedTeachers'), x => x.length)
      );

      const shouldUpsellParent = (
        (me.get('role') === 'parent') &&
        (needle2 = me.get('country'), !['australia', 'taiwan', 'hong-kong', 'netherlands', 'indonesia', 'singapore', 'malaysia'].includes(needle2)) &&
        !skipUpsellDueToExistingLicenses
      );

      this.state.set({ shouldUpsell, shouldUpsellParent });

      if ((shouldUpsell || shouldUpsellParent) && !this.upsellTracked) {
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
      const slackData = {
        channel: 'sales-feed',
        event: 'EnrollmentsView clicked contact us',
      };
      sendSlackMessage(slackData);
      if (window.tracker != null) {
        window.tracker.trackEvent('Classes Licenses Contact Us', {category: 'Teachers'});
      }
      const modal = new TeachersContactModal({
        shouldUpsell: this.state.get('shouldUpsell'),
        shouldUpsellParent: this.state.get('shouldUpsellParent')
      });
      this.openModalView(modal);
      return modal.on('submit', () => {
        this.enrollmentRequestSent = true;
        return this.debouncedRender();
      });
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

    onClickLicenseStats(e) {
      const prepaidID = $(e.currentTarget).data('prepaidId');
      this.licenseStatsModal = new LicenseStatsModal({prepaid: this.prepaids.get(prepaidID)});
      return this.openModalView(this.licenseStatsModal);
    }

    getEnrollmentExplanation() {
      const t = {};
      for (let i = 1; i <= 5; i++) {
        t[i] = $.i18n.t(`teacher.enrollment_explanation_${i}`);
      }
      return `<p>${t[1]} <b>${t[2]}</b> ${t[3]}</p><p><b>${t[4]}:</b> ${t[5]}</p>`;
    }
  };
  EnrollmentsView.initClass();
  return EnrollmentsView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}