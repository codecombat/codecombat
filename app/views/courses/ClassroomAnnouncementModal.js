/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ClassroomAnnouncementModal;
require('app/styles/courses/classroom-announcement-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('templates/courses/classroom-announcement-modal');
const DOMPurify = require('dompurify');

module.exports = (ClassroomAnnouncementModal = (function() {
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
})());
