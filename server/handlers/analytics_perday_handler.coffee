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
    return @getLevelSubscriptionsBySlugs(req, res) if args[1] is 'level_subscriptions'
    return @getRecurringRevenue(req, res) if args[1] is 'recurring_revenue'
    super(arguments...)


  getLevelSubscriptionsBySlugs: (req, res) ->
    # Send back an array of level subscriptions shown and purchased counts
    # Parameters:
    # slugs - level slugs
    # startDay - Inclusive, optional, YYYYMMDD e.g. '20141214'
    # endDay - Exclusive, optional, YYYYMMDD e.g. '20141216'

    levelSlugs = req.query.slugs or req.body.slugs
    startDay = req.query.startDay or req.body.startDay
    endDay = req.query.endDay or req.body.endDay

    # log.warn "level_subscriptions levelSlugs='#{levelSlugs}' startDay=#{startDay} endDay=#{endDay}"

    return @sendSuccess res, [] unless levelSlugs?

    # Cache results in app server memory for 1 day
    @levelSubscriptionsCache ?= {}
    @levelSubscriptionsCachedSince ?= new Date()
    if (new Date()) - @levelSubscriptionsCachedSince > 86400 * 1000
      @levelSubscriptionsCache = {}
      @levelSubscriptionsCachedSince = new Date()
    cacheKey = levelSlugs.join ''
    cacheKey += 's' + startDay if startDay?
    cacheKey += 'e' + endDay if endDay?
    return @sendSuccess res, subscriptions if subscriptions = @levelSubscriptionsCache[cacheKey]

    findQueryParams = {v: {$in: ['Show subscription modal', 'Finished subscription purchase', 'all'].concat(levelSlugs)}}
    AnalyticsString.find(findQueryParams).exec (err, documents) =>
      if err? then return @sendDatabaseError res, err

      levelStringIDSlugMap = {}
      for doc in documents
        showSubEventID = doc._id if doc.v is 'Show subscription modal'
        finishSubEventID = doc._id if doc.v is 'Finished subscription purchase'
        filterEventID =  doc._id if doc.v is 'all'
        levelStringIDSlugMap[doc._id] = doc.v if doc.v in levelSlugs

      return @sendSuccess res, [] unless showSubEventID? and finishSubEventID? and filterEventID?

      queryParams = {$and: [
        {e: {$in: [showSubEventID, finishSubEventID]}},
        {f: filterEventID},
        {l: {$in: Object.keys(levelStringIDSlugMap)}}
      ]}
      queryParams["$and"].push {d: {$gte: startDay}} if startDay?
      queryParams["$and"].push {d: {$lt: endDay}} if endDay?
      AnalyticsPerDay.find(queryParams).exec (err, documents) =>
        if err? then return @sendDatabaseError res, err

        levelEventCounts = {}
        for doc in documents
          levelEventCounts[doc.l] ?= {}
          levelEventCounts[doc.l][doc.e] ?= 0
          levelEventCounts[doc.l][doc.e] += doc.c

        subscriptions = []
        for levelID of levelEventCounts
          subsShown = 0
          subsPurchased = 0
          for eventID of levelEventCounts[levelID]
            subsShown = levelEventCounts[levelID][eventID] if parseInt(eventID) is showSubEventID
            subsPurchased = levelEventCounts[levelID][eventID] if parseInt(eventID) is finishSubEventID
          subscriptions.push
            level: levelStringIDSlugMap[levelID]
            shown: subsShown
            purchased: subsPurchased

        @levelSubscriptionsCache[cacheKey] = subscriptions
        @sendSuccess res, subscriptions

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
