// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let RestrictedToStudentsView;
import RootView from 'views/core/RootView';

export default RestrictedToStudentsView = (function() {
  RestrictedToStudentsView = class RestrictedToStudentsView extends RootView {
    static initClass() {
      this.prototype.id = 'restricted-to-students-view';
      this.prototype.template = require('app/templates/courses/restricted-to-students-view');
    }

    initialize() {
      return (window.tracker != null ? window.tracker.trackEvent('Restricted To Students Loaded', {category: 'Students'}) : undefined);
    }
  };
  RestrictedToStudentsView.initClass();
  return RestrictedToStudentsView;
})();
