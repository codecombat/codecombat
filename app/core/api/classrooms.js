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
  get({ classroomID }, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/classroom/${classroomID}`, options);
  },

  // TODO: Set this up to allow using classroomID instead
  getMembers({classroom}, options) {
    const classroomID = classroom._id;
    const {
      removeDeleted
    } = options;
    delete options.removeDeleted;
    const limit = 10;
    let skip = 0;
    const size = _.size(classroom.members);
    const url = `/db/classroom/${classroomID}/members`;
    if (options.data == null) { options.data = {}; }
    options.data.memberLimit = limit;
    options.remove = false;
    const jqxhrs = [];
    while (skip < size) {
      options.data.memberSkip = skip;
      jqxhrs.push(fetchJson(url, options));
      skip += limit;
    }
    return Promise.all(jqxhrs).then(function(data) {
      let users = _.flatten(data);
      if (removeDeleted) {
        users = _.filter(users, user => !user.deleted);
      }
      return users;
    });
  },

  getCourseLevels({classroomID, courseID}, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/classroom/${classroomID}/courses/${courseID}/levels`, options);
  },

  addMembers({classroomID, members}, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/classroom/${classroomID}/add-members`, _.assign({}, options, {
      method: 'POST',
      json: {members}
    }));
  },

  fetchByOwner(ownerId, options) {
    if (options == null) { options = {}; }
    let projectionString = "";
    if (Array.isArray(options.project)) {
      projectionString += `&project=${options.project.join(',')}`;
    }
    if (options.includeShared) {
      projectionString += "&includeShared=true";
    }
    return fetchJson(`/db/classroom?ownerID=${ownerId}${projectionString}`, {
      method: 'GET'
    });
  },

  fetchByCourseInstanceId(courseInstanceId) {
    return fetchJson(`/db/classroom?courseInstanceId=${courseInstanceId}`, {
      method: 'GET'
    });
  },

// classDetails = { aceConfig: {language: ''}, name: ''}
  post(classDetails, options) {
    if (options == null) { options = {}; }
    return fetchJson("/db/classroom",  _.assign({}, options, {
      method: 'POST',
      json: classDetails
    }));
  },

  fetchGameContent(classroomID, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/classroom/${classroomID}/game-content`, options);
  },

  inviteMembers({classroomID, emails, recaptchaResponseToken}, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/classroom/${classroomID}/invite-members`,  _.assign({}, options, {
      method: 'POST',
      json: {
        emails,
        recaptchaResponseToken
      }
    }));
  },

  removeMember({classroomID, userId}, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/classroom/${classroomID}/members/${userId}`,  _.assign({}, options, {
      method: 'DELETE'
    }));
  },

// updates = { archived: '', name: ''}
  update({classroomID, updates}, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/classroom/${classroomID}`,  _.assign({}, options, {
      method: 'PUT',
      json: updates
    }));
  },

  addPermission({ classroomID, permission }) {
    return fetchJson(`/db/classroom/${classroomID}/permission`,  _.assign({}, {
      method: 'POST',
      json: { permission }
    }));
  },

  getPermission({ classroomID }) {
    return fetchJson(`/db/classroom/${classroomID}/permission`, {
      method: 'GET'
    });
  },

  removePermission({ classroomID, permission }) {
    return fetchJson(`/db/classroom/${classroomID}/permission`,  _.assign({}, {
      method: 'DELETE',
      json: { permission }
    }));
  },

  getEdLinkClassrooms() {
    return fetchJson("/ed-link/classrooms",  _.assign({}, {
      method: 'GET'
    }));
  },

  getMembersByClassCode(code) { return fetchJson(`/db/classroom/${code}/members-by-code`); }
};
