// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let MineModal;
require('app/styles/modal/mine-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/core/mine-modal');
const Products = require('collections/Products');
const storage = require('core/storage');

// define expectations for good rates before releasing

module.exports = (MineModal = (function() {
  MineModal = class MineModal extends ModalView {
    constructor(...args) {
      this.onBuyNowButtonClick = this.onBuyNowButtonClick.bind(this);
      super(...args);
    }

    static initClass() {
      this.prototype.id = 'mine-modal';
      this.prototype.template = template;
      this.prototype.hasAnimated = false;
      this.prototype.events = {
        'click #close-modal': 'hide',
        'click #buy-now-button': 'onBuyNowButtonClick',
        'click #submit-button': 'onSubmitButtonClick'
      };
    }

    onBuyNowButtonClick(e) {
      if (window.tracker != null) {
        window.tracker.trackEvent("Mine Explored", {engageAction: "buy_button_click"});
      }
      $("#buy-now-button").hide();
      $("#submit-button").show();
      $("#details-header").text("Thanks for your interest");
      $("#info-text").hide();
      return $("#capacity-text").show();
    }

    onSubmitButtonClick(e) {
      storage.save('roblox-clicked', true);
      if (window.tracker != null) {
        window.tracker.trackEvent("Roblox Explored", {engageAction: "submit_button_click"});
      }
      return this.hide();
    }

    destroy() {
      $("#modal-wrapper").off('mousemove');
      return super.destroy();
    }
  };
  MineModal.initClass();
  return MineModal;
})());
