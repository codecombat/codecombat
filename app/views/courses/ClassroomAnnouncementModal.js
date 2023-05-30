// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ClassroomAnnouncementModal;
import 'app/styles/courses/classroom-announcement-modal.sass';
import ModalView from 'views/core/ModalView';
import template from 'templates/courses/classroom-announcement-modal';
import DOMPurify from 'dompurify';

export default ClassroomAnnouncementModal = (function() {
  ClassroomAnnouncementModal = class ClassroomAnnouncementModal extends ModalView {
    static initClass() {
      this.prototype.id = 'classroom-announcement-modal';
      this.prototype.template = template;
  
      this.prototype.events =
        {'click #close-modal': 'hide'};
    }

    constructor(options) {
      super(options);
      this.announcement = DOMPurify.sanitize(marked(options.announcement));
    }
  };
  ClassroomAnnouncementModal.initClass();
  return ClassroomAnnouncementModal;
})();
