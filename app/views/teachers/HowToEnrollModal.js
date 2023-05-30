/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let HowToEnrollModal;
import 'app/styles/teachers/how-to-enroll-modal.sass';
import ModalView from 'views/core/ModalView';

export default HowToEnrollModal = (function() {
  HowToEnrollModal = class HowToEnrollModal extends ModalView {
    static initClass() {
      this.prototype.id = 'how-to-enroll-modal';
      this.prototype.template = require('app/templates/teachers/how-to-enroll-modal');
    }
  };
  HowToEnrollModal.initClass();
  return HowToEnrollModal;
})();

