// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let CourseInstances;
import CourseInstance from 'models/CourseInstance';
import CocoCollection from 'collections/CocoCollection';

export default CourseInstances = (function() {
  CourseInstances = class CourseInstances extends CocoCollection {
    static initClass() {
      this.prototype.model = CourseInstance;
      this.prototype.url = '/db/course_instance';
    }
  
    fetchByOwner(ownerID, options) {
      if (options == null) { options = {}; }
      ownerID = ownerID.id || ownerID; // handle if they pass in a user
      if (options.data == null) { options.data = {}; }
      options.data.ownerID = ownerID;
      return this.fetch(options);
    }

    fetchForClassroom(classroomID, options) {
      if (options == null) { options = {}; }
      classroomID = classroomID.id || classroomID; // handle if they pass in a user
      if (options.data == null) { options.data = {}; }
      options.data.classroomID = classroomID;
      return this.fetch(options);
    }

    fetchByClassrooms(classroomIds, options) {
      if (options == null) { options = {}; }
      options = _.extend({
        url: "/db/course_instance/-/by-classrooms"
      }, options);
      if (options.data == null) { options.data = {}; }
      options.data.classroomIds = classroomIds;
      return this.fetch(options);
    }
  };
  CourseInstances.initClass();
  return CourseInstances;
})();
