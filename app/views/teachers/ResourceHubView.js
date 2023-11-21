/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ResourceHubView;
require('app/styles/teachers/resource-hub-view.sass');
const RootView = require('views/core/RootView');
const utils = require('core/utils');

module.exports = (ResourceHubView = (function() {
  ResourceHubView = class ResourceHubView extends RootView {
    static initClass() {
      this.prototype.id = 'resource-hub-view';
      this.prototype.template = require('app/templates/teachers/resource-hub-view');
  
      this.prototype.events =
        {'click .resource-link': 'onClickResourceLink'};
    }

    getTitle() { return $.i18n.t('teacher.resource_hub'); }

    initialize() {
      return __guard__(me.getClientCreatorPermissions(), x => x.then(() => (typeof this.render === 'function' ? this.render() : undefined)));
    }

    onClickResourceLink(e) {
      const link = __guard__($(e.target).closest('a'), x => x.attr('href'));
      return (window.tracker != null ? window.tracker.trackEvent('Teachers Click Resource Hub Link', { category: 'Teachers', label: link }) : undefined);
    }
  };
  ResourceHubView.initClass();
  return ResourceHubView;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}