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
  createSecret({clientID}, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/api-clients/${clientID}/new-secret`, _.assign({}, {
      method: 'POST',
      json: options
    }));
  },

  createAutoClanOwner({clientID}, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/api-clients/${clientID}/create-auto-clan-owner`, _.assign({}, {
      method: 'POST',
      json: options
    }));
  },

  getByName(clientName, options) {
    if (options == null) { options = {}; }
    if (options.data == null) { options.data = {}; }
    options.data.name = clientName;
    return fetchJson('/db/api-clients/name', options);
  },

  getAll(options) {
    if (options == null) { options = {}; }
    return fetchJson('/db/api-clients', options);
  },

  post(options) {
    if (options == null) { options = {}; }
    return fetchJson('/db/api-clients', _.assign({}, {
      method: 'POST',
      json: options
    }));
  },

  updateFeature({clientID, featureID}, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/api-clients/${clientID}/update-feature/${featureID}`, _.assign({}, {
      method: 'PUT',
      json: options
    }));
  },

  getByHandle(clientID, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/api-clients/${clientID}`, options);
  },

  editClient(client, options) {
    if (options == null) { options = {}; }
    return fetchJson('/db/api-clients', _.assign({}, options, {
      method: 'PUT',
      json: client
    }));
  },

  getLicenseStats(clientID, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/api-clients/${clientID}/license-stats`, options);
  },

  getPlayTimeStats(options) {
    if (options == null) { options = {}; }
    return fetchJson("/api/playtime-stats", options);
  },

  getApiClientId() {
    return fetchJson("/api/get-client-id");
  },

  getTeacherCount(clientID, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/api-clients/${clientID}/teacher-count`);
  },

  getTeachers(clientID, { skip, limit }) {
    return fetchJson(`/db/api-clients/${clientID}/teachers`, {
      method: 'GET',
      data: {
        skip,
        limit
      }
    });
  }
};
