/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let RestrictedToTeachersView;
const RootView = require('views/core/RootView');

module.exports = (RestrictedToTeachersView = (function() {
  RestrictedToTeachersView = class RestrictedToTeachersView extends RootView {
    static initClass() {
      this.prototype.id = 'restricted-to-teachers-view';
      this.prototype.template = require('app/templates/teachers/restricted-to-teachers-view');
    }

    initialize() {
      __guard__(me.getClientCreatorPermissions(), x => x.then(() => (typeof this.render === 'function' ? this.render() : undefined)));
      if (window.tracker) {
        window.tracker.trackEvent('Restricted To Teachers Loaded', { category: 'Students' })
      }
    }
  };
  RestrictedToTeachersView.initClass();
  return RestrictedToTeachersView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}