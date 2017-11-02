fetchJson = require './fetch-json'
utils = require 'core/utils'

module.exports = {
  getHeroes: (options) ->
    data = {
      view: 'heroes'
    }
    if options?.project
      _.assign data, {
        project: options.project.join(',')
      }
    return fetchJson('/db/thang.type', { data })
}
