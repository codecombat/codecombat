/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ShareProgressModal;
import 'app/styles/play/modal/share-progress-modal.sass';
import ModalView from 'views/core/ModalView';
import template from 'app/templates/play/modal/share-progress-modal';
import storage from 'core/storage';

export default ShareProgressModal = (function() {
  ShareProgressModal = class ShareProgressModal extends ModalView {
    static initClass() {
      this.prototype.id = 'share-progress-modal';
      this.prototype.template = template;
      this.prototype.plain = true;
      this.prototype.closesOnClickOutside = false;
  
      this.prototype.events = {
        'click .close-btn': 'hide',
        'click .continue-link': 'hide',
        'click .send-btn': 'onClickSend'
      };
    }

    onClickSend(e) {
      const email = $('.email-input').val();
      if (!/[\w\.]+@\w+\.\w+/.test(email)) {
        $('.email-input').parent().addClass('has-error');
        $('.email-invalid').show();
        return false;
      }

      const request = this.supermodel.addRequestResource('send_one_time_email', {
        url: '/db/user/-/send_one_time_email',
        data: {email, type: 'share progress modal parent'},
        method: 'POST'
      }, 0);
      request.load();

      storage.save('sent-parent-email', true);
      return this.hide();
    }
  };
  ShareProgressModal.initClass();
  return ShareProgressModal;
})();
