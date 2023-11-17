/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CourseNagModal;
require('app/styles/teachers/course-nag-modal.sass');
const ModalView = require('views/core/ModalView');

module.exports = (CourseNagModal = (function() {
  CourseNagModal = class CourseNagModal extends ModalView {
    static initClass() {
      this.prototype.id = 'course-nag-modal';
      this.prototype.template = require('app/templates/teachers/course-nag-modal');
    }
  };
  CourseNagModal.initClass();
  return CourseNagModal;
})());

