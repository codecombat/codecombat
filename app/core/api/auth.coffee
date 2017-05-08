fetchJson = require './fetch-json'

module.exports = {
  loginByIsraelId: (israelId, options) ->
    fetchJson('/auth/login-israel', _.assign({}, options, { method: 'POST', json: { israelId } }))
}
