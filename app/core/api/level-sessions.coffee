fetchJson = require './fetch-json'

module.exports = {
  submitToRank: ({ session, courseInstanceID }, options) ->
    fetchJson('/queue/scoring', _.merge({}, options, {
      method: 'POST'
      json: { session, courseInstanceID }
    }))
}
