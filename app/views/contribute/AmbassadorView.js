// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AmbassadorView;
const ContributeClassView = require('./ContributeClassView');
const template = require('app/templates/contribute/ambassador');
const {me} = require('core/auth');
const ContactModal = require('views/core/ContactModal');

module.exports = (AmbassadorView = (function() {
  AmbassadorView = class AmbassadorView extends ContributeClassView {
    static initClass() {
      this.prototype.id = 'ambassador-view';
      this.prototype.template = template;
  
      this.prototype.events =
        {'click [data-toggle="coco-modal"][data-target="core/ContactModal"]': 'openContactModal'};
    }

    initialize() {
      return this.contributorClassName = 'ambassador';
    }

    openContactModal(e) {
      e.stopPropagation();
      return this.openModalView(new ContactModal());
    }
  };
  AmbassadorView.initClass();
  return AmbassadorView;
})());
