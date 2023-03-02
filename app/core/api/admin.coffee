fetchJson = require './fetch-json'

module.exports = {
  clearFeatureMode: (options) ->
    fetchJson('/admin/feature-mode', _.assign({}, options, { method: 'DELETE' }))
    
  setFeatureMode: (featureMode, options) ->
    fetchJson("/admin/feature-mode/#{featureMode}", _.assign({}, options, { method: 'PUT' }))

  searchUser: (q) ->
    role = undefined
    q = q.replace /role:([^ ]+)/, (dummy, m1) ->
      role = m1
      return ''

    data = {adminSearch: q}
    data.role = role if role?
    fetchJson("/db/user", { data })
}
