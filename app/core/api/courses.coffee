fetchJson = require './fetch-json'

module.exports = {
  get: ({courseID}, options={}) ->
    fetchJson("/db/course/#{courseID}", options)

  getAll: (options={}) ->
    fetchJson("/db/course", options)

  fetchChangeLog: (options = {}) ->
    fetchJson("/db/course/change-log", options)
}
