// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let NotFoundView;
import 'app/styles/not_found.sass';
import RootView from 'views/core/RootView';
import template from 'app/templates/core/not-found';

export default NotFoundView = (function() {
  NotFoundView = class NotFoundView extends RootView {
    static initClass() {
      this.prototype.id = 'not-found-view';
      this.prototype.template = template;
    }
  };
  NotFoundView.initClass();
  return NotFoundView;
})();
