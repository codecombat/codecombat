fetchJson = require './fetch-json'

module.exports = {
  post: (trialRequest, options) ->
    fetchJson('/db/trial.request', _.assign({}, options, {
      method: 'POST',
      json: trialRequest
    }))
}
