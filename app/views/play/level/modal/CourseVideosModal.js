/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CourseVideosModal;
import ModalComponent from 'views/core/ModalComponent';
import CourseVideosModalComponent from './CourseVideosModalComponent.vue';

export default CourseVideosModal = (function() {
  CourseVideosModal = class CourseVideosModal extends ModalComponent {
    static initClass() {
      this.prototype.id = 'course-videos-modal';
      this.prototype.template = require('app/templates/core/modal-base-flat');
      this.prototype.VueComponent = CourseVideosModalComponent;
      this.prototype.propsData = null;
    }

    // Runs before the constructor is called.
    initialize() {
      return this.propsData = {
        courseInstanceID: null,
        courseID: null
      };
    }
    constructor(options) {
      super(options);
      this.propsData.courseInstanceID = (options != null ? options.courseInstanceID : undefined) || null;
      this.propsData.courseID = (options != null ? options.courseID : undefined) || null;
    }

    destroy() {
      if (typeof this.onDestroy === 'function') {
        this.onDestroy();
      }
      return super.destroy();
    }
  };
  CourseVideosModal.initClass();
  return CourseVideosModal;
})();
