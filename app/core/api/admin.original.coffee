fetchJson = require './fetch-json'

module.exports = {
  clearFeatureMode: (options) ->
    fetchJson('/admin/feature-mode', _.assign({}, options, { method: 'DELETE' }))
    
  setFeatureMode: (featureMode, options) ->
    fetchJson("/admin/feature-mode/#{featureMode}", _.assign({}, options, { method: 'PUT' }))

  searchUser: (query) ->
    role = undefined
    permission = undefined
    if typeof query is 'object'
      q = query.q
      role = query.role
      permissions = query.permissions
    else
      q = query.replace /role:([^ ]+) /, (dummy, m1) ->
        role = m1
        return ''

    data = {adminSearch: q}
    data.role = role if role?
    data.permissions = permissions if permissions?
    fetchJson("/db/user", { data })
}
