// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let DiplomatSuggestionModal;
import ModalView from 'views/core/ModalView';
import template from 'app/templates/core/diplomat-suggestion';
import { me } from 'core/auth';
import forms from 'core/forms';

export default DiplomatSuggestionModal = (function() {
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
})();
