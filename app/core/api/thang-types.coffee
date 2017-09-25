fetchJson = require './fetch-json'
utils = require 'core/utils'

module.exports = {
  getAll: (options) ->
    return fetchJson('/db/thang.type', options)
}
