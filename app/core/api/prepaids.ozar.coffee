fetchJson = require './fetch-json'

module.exports = {
  url: (prepaidID, path) -> if path then "/db/prepaid/#{prepaidID}/#{path}" else "/db/prepaid/#{prepaidID}"

  addJoiner: ({ prepaidID, userID }, options={}) ->
    fetchJson(@url(prepaidID, 'joiners'), _.assign {}, options, {
      method: 'POST'
      json: { userID }
    })

  fetchJoiners: ({ prepaidID }, options={}) ->
    fetchJson(@url(prepaidID, 'joiners'))
    
  getOwn: (options={}) ->
    options.data ?= {}
    options.data.creator = me.id
    fetchJson('/db/prepaid', options)

  post: (options={}) ->
    fetchJson('/db/prepaid', _.assign {}, {
      method: 'POST'
      json: options
    })

  getByCreator: (creatorId, options={}) ->
    options.data ?= {}
    options.data.creator = creatorId
    fetchJson('/db/prepaid', options)

  getByClient: (clientId, options={}) ->
    options.data ?= {}
    options.data.client = clientId
    fetchJson('/db/prepaid/client', options)

}
