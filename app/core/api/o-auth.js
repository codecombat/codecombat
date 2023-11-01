/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const fetchJson = require('./fetch-json');

module.exports = {
  
  post(options) {
    if (options == null) { options = {}; }
    return fetchJson('/db/o-auth', _.assign({}, {
      method: 'POST',
      json: options
    }));
  },

  editProvider(provider, options) {
    if (options == null) { options = {}; }
    return fetchJson('/db/o-auth', _.assign({}, options, {
      method: 'PUT',
      json: provider
    }));
  },

  getByName(providerName, options) {
    if (options == null) { options = {}; }
    if (options.data == null) { options.data = {}; }
    options.data.name = providerName;
    return fetchJson('/db/o-auth/name', options);
  },

  getAll(options) {
    if (options == null) { options = {}; }
    return fetchJson('/db/o-auth', options);
  }
};