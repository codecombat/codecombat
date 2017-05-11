fetchJson = require './fetch-json'

module.exports = {
  post: (classroom, options) ->
    fetchJson('/db/classroom', _.assign({}, options, {
      method: 'POST',
      json: classroom
    }))
}
