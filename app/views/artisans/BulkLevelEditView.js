// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let BulkLevelEditView;
import RootComponent from 'views/core/RootComponent';
import template from 'app/templates/base-flat';
import BulkLevelEditComponent from './BulkLevelEditComponent.vue';

export default BulkLevelEditView = (function() {
  BulkLevelEditView = class BulkLevelEditView extends RootComponent {
    static initClass() {
      this.prototype.id = 'bulk-level-edit-view';
      this.prototype.template = template;
      this.prototype.VueComponent = BulkLevelEditComponent;
    }

    constructor(options, campaignHandle) {
      super(options);
      this.propsData = { campaignHandle };
    }
  };
  BulkLevelEditView.initClass();
  return BulkLevelEditView;
})();
