fetchJson = require './fetch-json'

module.exports = {
  loginByIsraelIdOrToken: ({israelId, israelToken}, options) ->
    fetchJson('/auth/login-israel', _.assign({}, options, { method: 'POST', json: { israelId, israelToken } }))
    .then (user) ->
      me.set(user) # propagate
      return user
      
}
