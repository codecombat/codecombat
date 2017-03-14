fetchJson = require './fetch-json'

module.exports = {
  clearFeatureMode: (options) ->
    fetchJson('/admin/feature-mode', _.assign({}, options, { method: 'DELETE' }))
    
  setFeatureMode: (featureMode, options) ->
    fetchJson("/admin/feature-mode/#{featureMode}", _.assign({}, options, { method: 'PUT' }))
}
