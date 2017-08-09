fetchJson = require './fetch-json'

module.exports = {
  url: (prepaidID, path) -> if path then "/db/prepaid/#{prepaidID}/#{path}" else "/db/prepaid/#{prepaidID}"

  get: ({ prepaidID }, options) ->
    fetchJson(@url(prepaidID), options)
  
  put: ({ prepaid }, options) ->
    fetchJson(@url(prepaid._id), _.assign({}, options, {
      method: 'PUT',
      json: prepaid
    }))
  
  addJoiner: ({ prepaidID, userID }, options={}) ->
    fetchJson(@url(prepaidID, 'joiners'), _.assign {}, options, {
      method: 'POST'
      json: { userID }
    })

  fetchJoiners: ({ prepaidID }, options={}) ->
    fetchJson(@url(prepaidID, 'joiners'))
}
