// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CourseVideosView;
const RootComponent = require('views/core/RootComponent');
const CourseVideosComponent = require('./CourseVideosComponent').default;

module.exports = (CourseVideosView = (function() {
  CourseVideosView = class CourseVideosView extends RootComponent {
    static initClass() {
      this.prototype.id = 'course-videos-view';
      this.prototype.template = require('app/templates/base-flat');
      this.prototype.VueComponent = CourseVideosComponent;
    }
    constructor(options, courseID, courseName) {
      super(options);
      this.courseID = courseID;
      this.courseName = courseName;
      this.propsData = { courseID: this.courseID, courseName: this.courseName };
    }
  };
  CourseVideosView.initClass();
  return CourseVideosView;
})());
