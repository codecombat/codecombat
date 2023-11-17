// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let OzVsCocoView;
require('app/styles/modal/create-account-modal/oz-vs-coco-view.sass');
const CocoView = require('views/core/CocoView');
const template = require('app/templates/core/create-account-modal/oz-vs-coco-view');

module.exports = (OzVsCocoView = (function() {
  OzVsCocoView = class OzVsCocoView extends CocoView {
    static initClass() {
      this.prototype.id = 'oz-vs-coco-view';
      this.prototype.template = template;
  
      this.prototype.events = {
        'click .continue-codecombat'() { return this.trigger('nav-forward'); },
        'click .back-button'() { return this.trigger('nav-back'); }
      };
    }
  };
  OzVsCocoView.initClass();
  return OzVsCocoView;
})());
