AnalyticsLogEvent = require './AnalyticsLogEvent'
Handler = require '../commons/Handler'

class AnalyticsLogEventHandler extends Handler
  modelClass: AnalyticsLogEvent
  jsonSchema: require '../../app/schemas/models/analytics_log_event'
  editableProperties: [
    'event'
    'properties'
  ]

  hasAccess: (req) ->
    req.method in ['POST'] or req.user?.isAdmin()

  makeNewInstance: (req) ->
    instance = super(req)
    instance.set('user', req.user._id)
    instance

module.exports = new AnalyticsLogEventHandler()
