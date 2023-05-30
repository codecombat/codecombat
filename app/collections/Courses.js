// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Courses;
import Course from 'models/Course';
import CocoCollection from 'collections/CocoCollection';

export default Courses = (function() {
  Courses = class Courses extends CocoCollection {
    static initClass() {
      this.prototype.model = Course;
      this.prototype.url = '/db/course';
    }

    fetchReleased(options) {
      if (options == null) { options = {}; }
      if (options.data == null) { options.data = {}; }
      if (me.isInternal()) {
        options.data.fetchInternal = true; // will fetch 'released' and 'internalRelease' courses
      } else {
        options.data.releasePhase = 'released';
      }
      return this.fetch(options);
    }
  };
  Courses.initClass();
  return Courses;
})();
