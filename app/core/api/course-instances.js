// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
import fetchJson from './fetch-json';

export default {
  get({ courseInstanceID }, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/course_instance/${courseInstanceID}`, options);
  },

  getProjectGallery({ courseInstanceID }, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/course_instance/${courseInstanceID}/peer-projects`, options);
  },

  getSessions({ courseInstanceID }, options) {
    if (options == null) { options = {}; }
    const userID = (options != null ? options.userID : undefined) || me.id;
    return fetchJson(`/db/course_instance/${courseInstanceID}/course-level-sessions/${userID}`, options);
  },

  fetchByOwner(ownerID) {
    return fetchJson("/db/course_instance", {
      data: { ownerID }
    });
  },

  fetchByClassroom(classroomID) {
    return fetchJson("/db/course_instance", {
      data: { classroomID }
    });
  },

  // courseInstanceDetails = {classroomID: '', courseID: ''}
  post(courseInstanceDetails, options) {
    if (options == null) { options = {}; }
    return fetchJson("/db/course_instance", _.assign({}, options, {
      method: 'POST',
      json: courseInstanceDetails
    }));
  },

  removeMember(courseInstanceID, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/course_instance/${courseInstanceID}/members`, _.assign({}, options, {
      method: 'DELETE',
      json: {
        userID: options.memberId
      }
    }));
  }
};
