/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LiveClassroomModal;
import 'app/styles/play/modal/live-classroom-modal.sass';
import ModalView from 'views/core/ModalView';
import template from 'app/templates/play/modal/live-classroom-modal';

export default LiveClassroomModal = (function() {
  LiveClassroomModal = class LiveClassroomModal extends ModalView {
    static initClass() {
      this.prototype.template = template;
      this.prototype.id = 'live-classroom-modal';
  
      this.prototype.events = {
        'click #close-modal': 'hide',
        'mouseup #live-codecombat-link': 'onClickLiveClassesLink'
      };
    }

    onClickLiveClassesLink() {
      return (window.tracker != null ? window.tracker.trackEvent('Click Live Classes link', {label: 'live-classes-link'}) : undefined);
    }
  };
  LiveClassroomModal.initClass();
  return LiveClassroomModal;
})();
