fetchJson = require './fetch-json'

module.exports = {
  getByOriginal: (original) ->
    return fetchJson("/db/level/#{original}/version")
}
