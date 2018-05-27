fetchJson = require './fetch-json'

module.exports = {
  sendAPCSPAccessRequest: ({ name, email, message }, options={}) ->
    fetchJson('/contact/send-apcsp-access-request', _.assign({}, options, {
      method: 'POST'
      json: { name, email, message }
    }))
}
