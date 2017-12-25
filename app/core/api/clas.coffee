fetchJson = require './fetch-json'

module.exports = {
  getAll: (options={}) ->
    fetchJson("/db/cla.submissions", options)
}
