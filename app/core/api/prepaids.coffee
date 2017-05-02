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
}
