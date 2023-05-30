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
  get({courseID}, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/course/${courseID}`, options);
  },

  getAll(options) {
    if (options == null) { options = {}; }
    return fetchJson("/db/course", options);
  },

  getReleased(options) {
    if (options == null) { options = {}; }
    if (options.data == null) { options.data = {}; }
    if (me.isInternal()) {
      options.data.fetchInternal = true; // will fetch 'released' and 'internalRelease' courses
    } else {
      options.data.releasePhase = 'released';
    }
    return fetchJson("/db/course", options);
  },

  fetchChangeLog(options) {
    if (options == null) { options = {}; }
    return fetchJson("/db/course/change-log", options);
  },

  getAllClassroomLevels(options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/course/${options.courseId}/get-all-classroom-levels`);
  },

  addLevelsForAllClassroomsDryRun(options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/course/${options.courseId}/add-levels-for-all-classrooms`);
  },

  addLevelsForAllClasses(options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/course/${options.courseId}/add-levels-for-all-classrooms/yes-really-update-all-classrooms!-this-is-not-a-drill!`);
  }
};
