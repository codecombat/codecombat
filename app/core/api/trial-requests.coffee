fetchJson = require './fetch-json'

module.exports = {
  post: (trialRequest, options) ->
    fetchJson('/db/trial.request', _.assign({}, options, {
      method: 'POST',
      json: trialRequest
    }))
    
  getOwn: (options) ->
    options ?= {}
    options.data ?= {}
    options.data.applicant = me.id
    return fetchJson('/db/trial.request', options)
}
