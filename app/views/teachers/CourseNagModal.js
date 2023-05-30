/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CourseNagModal;
import 'app/styles/teachers/course-nag-modal.sass';
import ModalView from 'views/core/ModalView';

export default CourseNagModal = (function() {
  CourseNagModal = class CourseNagModal extends ModalView {
    static initClass() {
      this.prototype.id = 'course-nag-modal';
      this.prototype.template = require('app/templates/teachers/course-nag-modal');
    }
  };
  CourseNagModal.initClass();
  return CourseNagModal;
})();

