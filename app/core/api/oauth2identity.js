const fetchJson = require('./fetch-json')

module.exports = {

  post (options) {
    if (options == null) { options = {} }
    return fetchJson('/db/oauth2identity', _.assign({}, {
      method: 'POST',
      json: options,
    }))
  },

  fetchForProviderAndUser (provider, userId) {
    return fetchJson('/db/oauth2identity/by-user', { data: { userId, provider } })
  },
}
