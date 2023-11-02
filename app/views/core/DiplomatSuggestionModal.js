/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let DiplomatSuggestionModal;
const ModalView = require('views/core/ModalView');
const template = require('app/templates/core/diplomat-suggestion');
const {me} = require('core/auth');
const forms = require('core/forms');

module.exports = (DiplomatSuggestionModal = (function() {
  DiplomatSuggestionModal = class DiplomatSuggestionModal extends ModalView {
    static initClass() {
      this.prototype.id = 'diplomat-suggestion-modal';
      this.prototype.template = template;
  
      this.prototype.events =
        {'click #subscribe-button': 'subscribeAsDiplomat'};
    }

    subscribeAsDiplomat() {
      me.setEmailSubscription('diplomatNews', true);
      me.patch();
      $('#email_translator').prop('checked', 1);
      this.hide();
      noty({
        text: $.i18n.t('account_settings.saved'),
        layout: 'topCenter',
        timeout: 5000,
        type: 'information'
      });
      return Backbone.Mediator.publish('router:navigate',
        {route: "/contribute/diplomat"});
    }
  };
  DiplomatSuggestionModal.initClass();
  return DiplomatSuggestionModal;
})());
