fetchJson = require './fetch-json'

module.exports = {
  submitToRank: ({ session, courseInstanceID }, options) ->
    fetchJson('/queue/scoring', _.merge({}, options, {
      method: 'POST'
      json: { session, courseInstanceID }
    }))

  setKeyValue: ({ sessionID, key, value }, options) ->
    fetchJson("/db/level.session/#{sessionID}/key-value-db/#{key}", _.merge({}, options, {
      method: 'PUT'
      json: value
    }))

  incrementKeyValue: ({ sessionID, key, value=1 }, options) ->
    fetchJson("/db/level.session/#{sessionID}/key-value-db/#{key}/increment", _.merge({}, options, {
      method: 'POST'
      json: value
    }))

}
