fetchJson = require './fetch-json'

module.exports = {
  
  post: (options={}) ->
    fetchJson('/db/api-clients', _.assign {}, {
      method: 'POST'
      json: options
    })

  createSecret: ({clientID}, options={}) ->
    fetchJson("/db/api-clients/#{clientID}/new-secret", _.assign {}, {
      method: 'POST'
      json: options
    })

  getByName: (clientName, options={}) ->
    options.data ?= {}
    options.data.name = clientName
    fetchJson('/db/api-clients/name', options)

  getAll: (options={}) ->
    fetchJson('/db/api-clients', options)
}