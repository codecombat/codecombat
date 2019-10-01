fetchJson = require './fetch-json'

module.exports = {
  getAPCSPFile: (fileName, options) ->
    fetchJson('/apcsp-files/'+fileName, options)
}
