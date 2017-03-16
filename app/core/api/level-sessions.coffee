fetchJson = require './fetch-json'

module.exports = {
  submitToRank: ({ session, courseInstanceId }, options) ->
    fetchJson('/queue/scoring', _.merge({}, options, { 
      method: 'POST'
      json: { session, courseInstanceId }
    }))
}
