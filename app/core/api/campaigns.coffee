fetchJson = require './fetch-json'

module.exports = {
  getAll: (options={}) ->
    fetchJson("/db/campaign", options)
}
