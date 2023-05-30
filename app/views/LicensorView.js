// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LicensorView;
import RootComponent from 'views/core/RootComponent';
import template from 'app/templates/base-flat';
import LicensorViewComponent from './LicensorViewComponent.vue';

export default LicensorView = (function() {
  LicensorView = class LicensorView extends RootComponent {
    static initClass() {
      this.prototype.id = 'licensor-view';
      this.prototype.template = template;
      this.prototype.VueComponent = LicensorViewComponent;
    }
  };
  LicensorView.initClass();
  return LicensorView;
})();
