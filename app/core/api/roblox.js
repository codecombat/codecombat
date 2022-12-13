const fetchJson = require('./fetch-json')

module.exports = {
  waitlistSignup (options) {
    return fetchJson('/roblox/waitlist-signup', {
      method: 'POST',
      json: options
    })
  }
}
