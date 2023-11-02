// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LicensorView;
const RootComponent = require('views/core/RootComponent');
const template = require('app/templates/base-flat');
const LicensorViewComponent = require('./LicensorViewComponent.vue').default;

module.exports = (LicensorView = (function() {
  LicensorView = class LicensorView extends RootComponent {
    static initClass() {
      this.prototype.id = 'licensor-view';
      this.prototype.template = template;
      this.prototype.VueComponent = LicensorViewComponent;
    }
  };
  LicensorView.initClass();
  return LicensorView;
})());
 