AnalyticsString = require './../models/AnalyticsString'
Handler = require '../commons/Handler'

class AnalyticsStringHandler extends Handler
  modelClass: AnalyticsString
  jsonSchema: require '../../app/schemas/models/analytics_string'
  hasAccess: (req) -> req.method in ['GET'] or req.user?.isAdmin()

module.exports = new AnalyticsStringHandler()
