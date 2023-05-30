// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SandboxView;
import RootComponent from 'views/core/RootComponent';
import template from 'app/templates/base-flat';
import SandboxViewComponent from './SandboxViewComponent.vue';

export default SandboxView = (function() {
  SandboxView = class SandboxView extends RootComponent {
    static initClass() {
      this.prototype.id = 'sandbox-view';
      this.prototype.template = template;
      this.prototype.VueComponent = SandboxViewComponent;
    }

    constructor(options) {
      super(options);
    }
  };
  SandboxView.initClass();
  return SandboxView;
})();
