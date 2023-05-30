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
  url(prepaidID, path) { if (path) { return `/db/prepaid/${prepaidID}/${path}`; } else { return `/db/prepaid/${prepaidID}`; } },

  addJoiner({ prepaidID, userID }, options) {
    if (options == null) { options = {}; }
    return fetchJson(this.url(prepaidID, 'joiners'), _.assign({}, options, {
      method: 'POST',
      json: { userID }
    }));
  },

  revokeJoiner({ prepaidID, userID }, options) {
    if (options == null) { options = {}; }
    return fetchJson(this.url(prepaidID, 'joiners'), _.assign({}, options, {
      method: 'DELETE',
      json: { userID }
    }));
  },

  setJoinerMaxRedeemers({ prepaidID, userID, maxRedeemers}, options) {
    if (options == null) { options = {}; }
    return fetchJson(this.url(prepaidID, 'joiners'), _.assign({}, options, {
      method: 'PUT',
      json: { userID, maxRedeemers }
    }));
  },

  fetchJoiners({ prepaidID }, options) {
    if (options == null) { options = {}; }
    return fetchJson(this.url(prepaidID, 'joiners'));
  },
    
  getOwn(options) {
    if (options == null) { options = {}; }
    if (options.data == null) { options.data = {}; }
    options.data.creator = me.id;
    return fetchJson('/db/prepaid', options);
  },

  post(options) {
    if (options == null) { options = {}; }
    return fetchJson('/db/prepaid', _.assign({}, {
      method: 'POST',
      json: options
    }));
  },

  getByCreator(creatorId, options) {
    if (options == null) { options = {}; }
    if (options.data == null) { options.data = {}; }
    options.data.creator = creatorId;
    return fetchJson('/db/prepaid', options);
  },

  getByClient(clientId, options) {
    if (options == null) { options = {}; }
    if (options.data == null) { options.data = {}; }
    options.data.client = clientId;
    return fetchJson('/db/prepaid/client', options);
  },

  joinByCodes(options) {
    if (options == null) { options = {}; }
    return fetchJson('/db/prepaids/-/join-by-codes', options);
  }
};
