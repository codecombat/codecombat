fetchJson = require './fetch-json'

module.exports = {
  submitToRank: ({ session, courseInstanceID }, options) ->
    fetchJson('/queue/scoring', _.merge({}, options, {
      method: 'POST'
      json: { session, courseInstanceID }
    }))

  getByStudentsAndLevels: ({ earliestCreated, studentIds, levelOriginals, project }, options) ->
    fetchJson("/db/level.session/-/levels-and-students", _.merge({}, options, {
      method: 'POST'
      json: { earliestCreated, studentIds, levelOriginals, project }
    }))

  setKeyValue: ({ sessionID, key, value }, options) ->
    fetchJson("/db/level.session/#{sessionID}/key-value-db/#{key}", _.merge({}, options, {
      method: 'PUT'
      json: value
    }))

  incrementKeyValue: ({ sessionID, key, value }, options) ->
    value ?= 1
    fetchJson("/db/level.session/#{sessionID}/key-value-db/#{key}/increment", _.merge({}, options, {
      method: 'POST'
      json: value
    }))

}
