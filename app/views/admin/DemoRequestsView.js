// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS202: Simplify dynamic range loops
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let DemoRequestsView;
require('app/styles/admin/demo-requests.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/admin/demo-requests');
const CocoCollection = require('collections/CocoCollection');
const TrialRequest = require('models/TrialRequest');

module.exports = (DemoRequestsView = (function() {
  DemoRequestsView = class DemoRequestsView extends RootView {
    static initClass() {
      this.prototype.id = 'admin-demo-requests-view';
      this.prototype.template = template;
    }

    constructor(options) {
      super(options);
      if (!me.isAdmin()) { return; }
      this.trialRequests = new CocoCollection([], { url: '/db/trial.request?conditions[sort]="-created"&conditions[limit]=10000', model: TrialRequest });
      this.supermodel.loadCollection(this.trialRequests, 'trial-requests', {cache: false});
      this.dayCounts = [];
    }

    onLoaded() {
      let count, day;
      if (!me.isAdmin()) { return super.onLoaded(); }
      const dayCountMap = {};
      for (var trialRequest of Array.from(this.trialRequests.models)) {
        day = trialRequest.get('created').substring(0, 10);
        if (dayCountMap[day] == null) { dayCountMap[day] = 0; }
        dayCountMap[day]++;
      }
      this.dayCounts = [];
      for (day in dayCountMap) {
        count = dayCountMap[day];
        this.dayCounts.push({day, count});
      }
      this.dayCounts.sort((a, b) => b.day.localeCompare(a.day));
      const sevenCounts = [];
      for (let start = this.dayCounts.length - 1, i = start, asc = start <= 0; asc ? i <= 0 : i >= 0; asc ? i++ : i--) {
        var dayCount = this.dayCounts[i];
        sevenCounts.push(dayCount.count);
        while (sevenCounts.length > 7) {
          sevenCounts.shift();
        }
        if (sevenCounts.length === 7) {
          dayCount.sevenAverage = Math.round(sevenCounts.reduce(((a, b) => a + b), 0) / 7);
        }
      }
      return super.onLoaded();
    }
  };
  DemoRequestsView.initClass();
  return DemoRequestsView;
})());
