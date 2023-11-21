// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CLAsView;
const RootComponent = require('views/core/RootComponent');
const template = require('app/templates/base-flat');
const CLAsComponent = require('./CLAsComponent.vue').default;

module.exports = (CLAsView = (function() {
  CLAsView = class CLAsView extends RootComponent {
    static initClass() {
      this.prototype.id = 'admin-clas-view';
      this.prototype.template = template;
      this.prototype.VueComponent = CLAsComponent;
    }
  };
  CLAsView.initClass();
  return CLAsView;
})());
