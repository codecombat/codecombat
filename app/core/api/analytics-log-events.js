fetchJson = require './fetch-json'

module.exports = {
  post: ({event, properties}, options) ->
    fetchJson('/db/analytics.log.event/-/log_event', _.assign({}, options, {
      method: 'POST',
      json: {
        event,
        properties
      }
    }))
}
