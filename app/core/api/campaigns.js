/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const fetchJson = require('./fetch-json');

module.exports = {
  getAll(options) {
    if (options == null) { options = {}; }
    return fetchJson("/db/campaign", options);
  },
  get({ campaignHandle }, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/campaign/${campaignHandle}`, options);
  },
  fetchGameContent(campaignHandle, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/campaign/${campaignHandle}/game-content`, options);
  },
  fetchOverworld(options) {
    if (options == null) { options = {}; }
    return fetchJson("/db/campaign/-/overworld", options);
  },
  fetchLevels(campaignHandle, options) {
    if (options == null) { options = {}; }
    return fetchJson(`/db/campaign/${campaignHandle}/levels`, options);
  }

};
