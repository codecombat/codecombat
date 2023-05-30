// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AdminSubCancellationsView;
const RootView = require('views/core/RootView');
const CocoCollection = require('collections/CocoCollection');
const utils = require('core/utils');

module.exports = (AdminSubCancellationsView = (function() {
  AdminSubCancellationsView = class AdminSubCancellationsView extends RootView {
    static initClass() {
      this.prototype.id = 'admin-sub-cancellations-view';
      this.prototype.template = require('app/templates/admin/admin-sub-cancellations');
    }

    initialize() {
      if (!me.isAdmin()) { return super.initialize(); }
      this.objectIdToDate = utils.objectIdToDate;
      this.limit = utils.getQueryVariable('limit', 100);
      const url = '/db/analytics.log.event?filter[event]="Unsubscribe End"&conditions[sort]="-_id"&conditions[limit]=' + this.limit;
      Promise.resolve($.get(url))
      .then(cancelEvents => {
        this.cancelEvents = cancelEvents;
        return (typeof this.render === 'function' ? this.render() : undefined);
      });
      return super.initialize();
    }
  };
  AdminSubCancellationsView.initClass();
  return AdminSubCancellationsView;
})());
