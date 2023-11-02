fetchJson = require './fetch-json'

module.exports = {
  createSecret: ({clientID}, options={}) ->
    fetchJson("/db/api-clients/#{clientID}/new-secret", _.assign {}, {
      method: 'POST'
      json: options
    })

  createAutoClanOwner: ({clientID}, options={}) ->
    fetchJson("/db/api-clients/#{clientID}/create-auto-clan-owner", _.assign {}, {
      method: 'POST'
      json: options
    })

  getByName: (clientName, options={}) ->
    options.data ?= {}
    options.data.name = clientName
    fetchJson('/db/api-clients/name', options)

  getAll: (options={}) ->
    fetchJson('/db/api-clients', options)

  post: (options={}) ->
    fetchJson('/db/api-clients', _.assign {}, {
      method: 'POST'
      json: options
    })

  updateFeature: ({clientID, featureID}, options={}) ->
    fetchJson("/db/api-clients/#{clientID}/update-feature/#{featureID}", _.assign {}, {
      method: 'PUT'
      json: options
    })

  getByHandle: (clientID, options={}) ->
    fetchJson("/db/api-clients/#{clientID}", options)

  editClient: (client, options={}) ->
    fetchJson('/db/api-clients', _.assign({}, options, {
      method: 'PUT'
      json: client
    }))

  getLicenseStats: (clientID, { startDate, endDate } = {}, options={}) ->
    url = "/db/api-clients/#{clientID}/license-stats"
    if startDate and endDate
      url = "#{url}?start-date=#{startDate}&end-date=#{endDate}"
    fetchJson(url, options)

  getPlayTimeStats: (options={}) ->
    fetchJson("/api/playtime-stats", options)

  getApiClientId: () ->
    fetchJson("/api/get-client-id")

  getTeacherCount: (clientID, options={}) ->
    fetchJson("/db/api-clients/#{clientID}/teacher-count")

  getTeachers: (clientID, { skip, limit }) ->
    fetchJson("/db/api-clients/#{clientID}/teachers", {
      method: 'GET',
      data: {
        skip,
        limit
      }
    })
}
