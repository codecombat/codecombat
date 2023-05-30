// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ContactCNView;
import 'app/styles/contact-cn.sass';
import RootView from 'views/core/RootView';
import template from 'app/templates/contact-cn-view';

export default ContactCNView = (function() {
  ContactCNView = class ContactCNView extends RootView {
    static initClass() {
      this.prototype.id = 'contact-view';
      this.prototype.template = template;
    }
  };
  ContactCNView.initClass();
  return ContactCNView;
})();
