fetchJson = require './fetch-json'

module.exports = {
  
  post: (options={}) ->
    fetchJson('/db/o-auth', _.assign {}, {
      method: 'POST'
      json: options
    })

  editProvider: (provider, options={}) ->
    fetchJson('/db/o-auth', _.assign({}, options, {
      method: 'PUT'
      json: provider
    }))

  getByName: (providerName, options={}) ->
    options.data ?= {}
    options.data.name = providerName
    fetchJson('/db/o-auth/name', options)

  getAll: (options={}) ->
    fetchJson('/db/o-auth', options)
}