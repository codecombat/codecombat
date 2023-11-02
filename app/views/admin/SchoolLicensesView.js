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
let SchoolLicensesView;
require('app/styles/admin/admin-school-licenses.sass');
const RootView = require('views/core/RootView');
const CocoCollection = require('collections/CocoCollection');
const Prepaid = require('models/Prepaid');
const TrialRequests = require('collections/TrialRequests');

// TODO: year ranges hard-coded

module.exports = (SchoolLicensesView = (function() {
  SchoolLicensesView = class SchoolLicensesView extends RootView {
    static initClass() {
      this.prototype.id = 'admin-school-licenses-view';
      this.prototype.template = require('app/templates/admin/school-licenses');
    }

    initialize() {
      if (!me.isAdmin()) { return super.initialize(); }
      this.startDateRange = new Date();
      this.endDateRange = new Date();
      this.endDateRange.setUTCFullYear(this.endDateRange.getUTCFullYear() + 2);
      this.supermodel.addRequestResource({
        url: '/db/prepaid/-/active-schools',
        method: 'GET',
        success: ({prepaidActivityMap, schoolPrepaidsMap}) => {
          return this.updateSchools(prepaidActivityMap, schoolPrepaidsMap);
        }
      }, 0).load();
      return super.initialize();
    }

    updateSchools(prepaidActivityMap, schoolPrepaidsMap) {
      let activity, endDate, max, prepaids, used;
      const timeStart = this.startDateRange.getTime();
      const time2017 = new Date('2017').getTime();
      const time2018 = new Date('2018').getTime();
      const timeEnd = this.endDateRange.getTime();
      const rangeMilliseconds = timeEnd - timeStart;
      this.rangeKeys = [
        {name :'Today', color: 'blue', startScale: 0, width: Math.round(((time2017 - timeStart) / rangeMilliseconds) * 100)},
        {name: '2017', color: 'red', startScale: Math.round(((time2017 - timeStart) / rangeMilliseconds) * 100), width: Math.round(((time2018 - time2017) / rangeMilliseconds) * 100)},
        {name: '2018', color: 'yellow', startScale: Math.round(((time2018 - timeStart) / rangeMilliseconds) * 100), width: Math.round(((timeEnd - time2018) / rangeMilliseconds) * 100)}
      ];

      this.schools = [];
      for (var school in schoolPrepaidsMap) {
        var collapsedPrepaid, startDate;
        prepaids = schoolPrepaidsMap[school];
        activity = 0;
        var schoolMax = 0;
        var schoolUsed = 0;
        var collapsedPrepaids = [];
        for (var prepaid of Array.from(prepaids)) {
          activity += prepaidActivityMap[prepaid._id] != null ? prepaidActivityMap[prepaid._id] : 0;
          ({
            startDate
          } = prepaid);
          ({
            endDate
          } = prepaid);
          max = parseInt(prepaid.maxRedeemers);
          used = parseInt((prepaid.redeemers != null ? prepaid.redeemers.length : undefined) != null ? (prepaid.redeemers != null ? prepaid.redeemers.length : undefined) : 0);
          schoolMax += max;
          schoolUsed += used;
          var foundIdenticalDates = false;
          for (collapsedPrepaid of Array.from(collapsedPrepaids)) {
            if ((collapsedPrepaid.startDate.substring(0, 10) === startDate.substring(0, 10)) && (collapsedPrepaid.endDate.substring(0, 10) === endDate.substring(0, 10))) {
              collapsedPrepaid.max += parseInt(prepaid.maxRedeemers);
              collapsedPrepaid.used += parseInt((prepaid.redeemers != null ? prepaid.redeemers.length : undefined) != null ? (prepaid.redeemers != null ? prepaid.redeemers.length : undefined) : 0);
              foundIdenticalDates = true;
              break;
            }
          }
          if (!foundIdenticalDates) {
            collapsedPrepaids.push({startDate, endDate, max, used});
          }
        }

        for (collapsedPrepaid of Array.from(collapsedPrepaids)) {
          collapsedPrepaid.startScale = ((new Date(collapsedPrepaid.startDate).getTime() - this.startDateRange.getTime()) / rangeMilliseconds) * 100;
          if (collapsedPrepaid.startScale < 0) {
            collapsedPrepaid.startScale = 0;
            collapsedPrepaid.rangeScale = ((new Date(collapsedPrepaid.endDate).getTime() - this.startDateRange.getTime()) / rangeMilliseconds) * 100;
          } else {
            collapsedPrepaid.rangeScale = ((new Date(collapsedPrepaid.endDate).getTime() - new Date(collapsedPrepaid.startDate).getTime()) / rangeMilliseconds) * 100;
          }
          if ((collapsedPrepaid.rangeScale + collapsedPrepaid.startScale) > 100) { collapsedPrepaid.rangeScale = 100 - collapsedPrepaid.startScale; }
        }
        this.schools.push({name: school, activity, max: schoolMax, used: schoolUsed, prepaids: collapsedPrepaids, startDate: collapsedPrepaids[0].startDate, endDate: collapsedPrepaids[0].endDate});
      }

      this.schools.sort((a, b) => (b.activity - a.activity) || (new Date(a.endDate).getTime() - new Date(b.endDate).getTime()) || (b.max - a.max) || (b.used - a.used) || (b.prepaids.length - a.prepaids.length) || b.name.localeCompare(a.name));

      return this.render();
    }
  };
  SchoolLicensesView.initClass();
  return SchoolLicensesView;
})());
