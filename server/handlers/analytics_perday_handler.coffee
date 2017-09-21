AnalyticsPerDay = require './../models/AnalyticsPerDay'
AnalyticsString = require './../models/AnalyticsString'
Campaign = require '../models/Campaign'
Level = require '../models/Level'
Handler = require '../commons/Handler'
log = require 'winston'

class AnalyticsPerDayHandler extends Handler
  modelClass: AnalyticsPerDay
  jsonSchema: require '../../app/schemas/models/analytics_perday'

  hasAccess: (req) ->
    req.user?.isAdmin() or false

  getByRelationship: (req, res, args...) ->
    return @sendForbiddenError res unless @hasAccess req
    return @getRecurringRevenue(req, res) if args[1] is 'recurring_revenue'
    super(arguments...)


  getRecurringRevenue: (req, res) ->
    events = [
      'DRR gems',
      'DRR school sales',
      'DRR yearly subs',
      'DRR monthly subs',
      'DRR paypal']

    AnalyticsString.find({v: {$in: events}}).exec (err, documents) =>
      return @sendDatabaseError(res, err) if err
      eventIDs = []
      eventStringMap = {}
      for doc in documents
        eventStringMap[doc._id.valueOf()] = doc.v
        eventIDs.push doc._id
      return @sendSuccess res, [] unless eventIDs.length is events.length

      AnalyticsPerDay.find({e: {$in: eventIDs}}).exec (err, documents) =>
        return @sendDatabaseError(res, err) if err
        dayCountsMap = {}
        for doc in documents
          dayCountsMap[doc.d] ?= {}
          dayCountsMap[doc.d][eventStringMap[doc.e.valueOf()]] = doc.c
        recurringRevenue = []
        for key, val of dayCountsMap
          recurringRevenue.push day: key, groups: dayCountsMap[key] ? {}
        @sendSuccess(res, recurringRevenue)


module.exports = new AnalyticsPerDayHandler()
