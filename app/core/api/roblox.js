const fetchJson = require('./fetch-json')

module.exports = {
  waitlistSignup (options) {
    return fetchJson('/roblox/waitlist-signup', {
      method: 'POST',
      json: options
    })
  },

  getConnectionsCount (options) {
    return fetchJson('/db/oauth2identity/count?filter[provider]=roblox', {
      method: 'GET'
    })
  }
}
