fetchJson = require './fetch-json'

module.exports = {
  fetchAll: (options) ->
    fetchJson('/db/skipped-contact', options)

  put: (skippedContact, options) ->
    fetchJson("/db/skipped-contact/#{skippedContact._id}", _.assign({}, options, {
      method: 'PUT'
      json: skippedContact
    }))
}
