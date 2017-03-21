AnalyticsUsersActive = require './../models/AnalyticsUsersActive'
Handler = require '../commons/Handler'

class AnalyticsUsersActiveHandler extends Handler
  modelClass: AnalyticsUsersActive
  jsonSchema: require '../../app/schemas/models/analytics_users_active'

  hasAccess: (req) ->
    req.method in ['GET'] or req.user?.isAdmin()

  makeNewInstance: (req) ->
    instance = super(req)
    instance.set('creator', req.user._id)
    instance

module.exports = new AnalyticsUsersActiveHandler()
