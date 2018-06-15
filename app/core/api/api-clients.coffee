fetchJson = require './fetch-json'

module.exports = {

  url: (clientID) -> "db/api-clients/#{clientID}/new-secret"
  
  post: (options={}) ->
    fetchJson('db/api-clients', _.assign {}, {
      method: 'POST'
      json: options
    })

  createSecret: ({clientID}, options={}) ->
    fetchJson(@url(clientID), _.assign {}, {
      method: 'POST'
      json: options
    })

  getByName: (clientName, options={}) ->
    options.data ?= {}
    options.data.name = clientName
    fetchJson('db/api-clients', options)
}