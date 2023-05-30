/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ContactCNView;
require('app/styles/contact-cn.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/contact-cn-view');

module.exports = (ContactCNView = (function() {
  ContactCNView = class ContactCNView extends RootView {
    static initClass() {
      this.prototype.id = 'contact-view';
      this.prototype.template = template;
    }
  };
  ContactCNView.initClass();
  return ContactCNView;
})());
