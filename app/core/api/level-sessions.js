// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const fetchJson = require('./fetch-json');

module.exports = {
  submitToRank({ session, courseInstanceId }, options) {
    return fetchJson('/queue/scoring', _.merge({}, options, {
      method: 'POST',
      json: { session, courseInstanceId }
    }));
  },

  getByStudentsAndLevels({ earliestCreated, studentIds, levelOriginals, project }, options) {
    return fetchJson("/db/level.session/-/levels-and-students", _.merge({}, options, {
      method: 'POST',
      json: { earliestCreated, studentIds, levelOriginals, project }
    }));
  },

  setKeyValue({ sessionID, key, value }, options) {
    return fetchJson(`/db/level.session/${sessionID}/key-value-db/${key}`, _.merge({}, options, {
      method: 'PUT',
      json: value
    }));
  },

  incrementKeyValue({ sessionID, key, value }, options) {
    if (value == null) { value = 1; }
    return fetchJson(`/db/level.session/${sessionID}/key-value-db/${key}/increment`, _.merge({}, options, {
      method: 'POST',
      json: value
    }));
  },

  fetchForClassroomMembers(classroomID, options) {
    return fetchJson(`/db/classroom/${classroomID}/member-sessions`, _.merge({}, options, {
      method: 'GET',
      remove: false
    }));
  },

  update(levelSession, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/level.session/${levelSession._id}`, _.assign({}, options, {
      method: 'PUT',
      json: levelSession
    }));
  },
  
  fetchMySessions(levelOriginal, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/level/${levelOriginal}/my_sessions`, options);
  },

  fetchForCampaign(campaignHandle, options) {
    return fetchJson(`/db/campaign/${campaignHandle}/sessions`, options);
  },

  fetchCompletedByDate(date, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/level.session/${me.id}/completed/${date}`, options);
  }
};
