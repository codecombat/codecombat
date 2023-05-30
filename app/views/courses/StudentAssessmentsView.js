// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let StudentAssessmentsView;
import RootComponent from 'views/core/RootComponent';
import StudentAssessmentsComponent from './StudentAssessmentsComponent';

export default StudentAssessmentsView = (function() {
  StudentAssessmentsView = class StudentAssessmentsView extends RootComponent {
    static initClass() {
      this.prototype.id = 'student-assessments-view';
      this.prototype.template = require('app/templates/base-flat');
      this.prototype.VueComponent = StudentAssessmentsComponent;
    }
    constructor(options, classroomID) {
      this.classroomID = classroomID;
      this.propsData = { classroomID: this.classroomID };
      super(options);
    }
  };
  StudentAssessmentsView.initClass();
  return StudentAssessmentsView;
})();
