// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let RecoverModal;
require('app/styles/modal/recover-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/core/recover-modal');
const forms = require('core/forms');
const {genericFailure} = require('core/errors');

const filterKeyboardEvents = (allowedEvents, func) => (function(...splat) {
  const e = splat[0];
  if (!Array.from(allowedEvents).includes(e.keyCode) && !!e.keyCode) { return; }
  return func(...Array.from(splat || []));
});

module.exports = (RecoverModal = (function() {
  RecoverModal = class RecoverModal extends ModalView {
    static initClass() {
      this.prototype.id = 'recover-modal';
      this.prototype.template = template;

      this.prototype.events = {
        'click #recover-button': 'recoverAccount',
        'keydown input': 'recoverAccount'
      };

      this.prototype.subscriptions =
        {'errors:server-error': 'onServerError'};
    }

    onServerError(e) { // TODO: work error handling into a separate forms system
      return this.disableModalInProgress(this.$el);
    }

    constructor(options) {
      super(options);
      this.recoverAccount = this.recoverAccount.bind(this);
      this.successfullyRecovered = this.successfullyRecovered.bind(this);
      this.recoverAccount = filterKeyboardEvents([13], this.recoverAccount); // TODO: part of forms
    }

    recoverAccount(e) {
      this.playSound('menu-button-click');
      forms.clearFormAlerts(this.$el);
      const {
        email
      } = forms.formToObject(this.$el);
      if (!email) { return; }
      const res = $.post('/auth/reset', {email}, this.successfullyRecovered);
      res.fail(genericFailure);
      return this.enableModalInProgress(this.$el);
    }

    successfullyRecovered() {
      this.disableModalInProgress(this.$el);
      this.$el.find('.modal-body:visible').text($.i18n.t('recover.recovery_sent'));
      return this.$el.find('.modal-footer').remove();
    }
  };
  RecoverModal.initClass();
  return RecoverModal;
})());
