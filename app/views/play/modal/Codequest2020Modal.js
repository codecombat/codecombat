/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LiveClassroomModal;
import 'app/styles/play/modal/codequest-2020-modal.sass';
import ModalView from 'views/core/ModalView';
import template from 'app/templates/play/modal/codequest-2020-modal.pug';

export default LiveClassroomModal = (function() {
  LiveClassroomModal = class LiveClassroomModal extends ModalView {
    static initClass() {
      this.prototype.template = template;
      this.prototype.id = 'codequest-2020-modal';
  
      this.prototype.events =
        {'click #close-modal': 'hide'};
    }
  };
  LiveClassroomModal.initClass();
  return LiveClassroomModal;
})();
