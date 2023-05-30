// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let OutcomesReportResultView;
import 'app/styles/admin/admin-outcomes-report.sass';
import utils from 'core/utils';
import RootView from 'views/core/RootView';

export default OutcomesReportResultView = (function() {
  OutcomesReportResultView = class OutcomesReportResultView extends RootView {
    static initClass() {
      this.prototype.id = 'admin-outcomes-report-result-view';
      this.prototype.template = require('app/templates/admin/outcome-report-result-view');
      this.prototype.events = {
        'click .back-btn': 'onClickBackButton',
        'click .print-btn': 'onClickPrintButton'
      };
    }
    initialize(options) {
      this.options = options;
      if (!me.isAdmin()) { return super.initialize(); }
      this.format = _.identity;

      if (__guard__(typeof window !== 'undefined' && window !== null ? window.Intl : undefined, x => x.NumberFormat) != null) {
        const intl = new window.Intl.NumberFormat();
        this.format = intl.format.bind(intl);
      }

      this.courses = this.options.courses.map(course => {
        return _.merge(course, {completion: this.options.courseCompletion[course._id].completion});
    });

      // Reorder CS2 in front of WD1/GD1 if it's more completed, to account for us changing the order around.
      const cs1 = _.find(this.courses, {slug: 'introduction-to-computer-science'});
      const cs2 = _.find(this.courses, {slug: 'computer-science-2'});
      const gd1 = _.find(this.courses, {slug: 'game-development-1'});
      const wd1 = _.find(this.courses, {slug: 'web-development-1'});

      if ((cs2 != null ? cs2.completion : undefined) > _.max([(gd1 != null ? gd1.completion : undefined), (wd1 != null ? wd1.completion : undefined)])) {
        this.courses.splice(this.courses.indexOf(cs2), 1);
        this.courses.splice(_.max([this.courses.indexOf(cs1), 0]) + 1, 0, cs2);
      }
      return super.initialize();
    }

    onClickBackButton() {
      console.log("Back View is", this.options.backView);
      return application.router.openView(this.options.backView);
    }

    onClickPrintButton() {
      return window.print();
    }
  };
  OutcomesReportResultView.initClass();
  return OutcomesReportResultView;
})();

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}