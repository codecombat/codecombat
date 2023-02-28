const fetchJson = require('./fetch-json')

module.exports = {
  register (options) {
    return fetchJson('/mobile/new-registration', {
      method: 'POST',
      json: options
    })
  }
}
