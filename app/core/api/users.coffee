fetchJson = require './fetch-json'

module.exports = {
  getByHandle: (handle, options) ->
    fetchJson("/db/user/#{handle}", options)
}
