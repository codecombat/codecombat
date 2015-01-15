AnalyticsPerDay = require './AnalyticsPerDay'
AnalyticsString = require './AnalyticsString'
Campaign = require '../campaigns/Campaign'
Level = require '../levels/Level'
Handler = require '../commons/Handler'
log = require 'winston'

class AnalyticsPerDayHandler extends Handler
  modelClass: AnalyticsPerDay
  jsonSchema: require '../../app/schemas/models/analytics_perday'

  hasAccess: (req) ->
    req.method in ['GET'] or req.user?.isAdmin()

  getByRelationship: (req, res, args...) ->
    return @getCampaignCompletionsBySlug(req, res) if args[1] is 'campaign_completions'
    return @getLevelCompletionsBySlug(req, res) if args[1] is 'level_completions'
    super(arguments...)

  getCampaignCompletionsBySlug: (req, res) ->
    # Send back an array of level starts and finishes
    # Parameters:
    # slug - campaign slug
    # startDay - Inclusive, optional, YYYYMMDD e.g. '20141214'
    # endDay - Exclusive, optional, YYYYMMDD e.g. '20141216'

    campaignSlug = req.query.slug or req.body.slug
    startDay = req.query.startDay or req.body.startDay
    endDay = req.query.endDay or req.body.endDay

    # log.warn "campaign_completions campaignSlug='#{campaignSlug}' startDay=#{startDay} endDay=#{endDay}"

    return @sendSuccess res, [] unless campaignSlug?

    # Cache results in app server memory for 1 day
    @campaignCompletionsCache ?= {}
    @campaignCompletionsCachedSince ?= new Date()
    if (new Date()) - @campaignCompletionsCachedSince > 86400 * 1000
      @campaignCompletionsCache = {}
      @campaignCompletionsCachedSince = new Date()
    cacheKey = campaignSlug
    cacheKey += 's' + startDay if startDay?
    cacheKey += 'e' + endDay if endDay?
    return @sendSuccess res, campaignDropOffs if campaignDropOffs = @campaignCompletionsCache[cacheKey]

    getCompletions = (orderedLevelSlugs, levelStringIDSlugMap) =>
      # 3. Send back an array of level starts and finishes
      # Input:
      # orderedLevelSlugs - Ordered list of level slugs, used for sorting results
      # levelStringIDSlugMap - Maps level string IDs to level slugs

      campaignLevelIDs = Object.keys(levelStringIDSlugMap)

      AnalyticsString.find({v: {$in: ['Started Level', 'Saw Victory', 'all']}}).exec (err, documents) =>
        if err? then return @sendDatabaseError res, err

        for doc in documents
          startEventID = doc._id if doc.v is 'Started Level'
          finishEventID = doc._id if doc.v is 'Saw Victory'
          filterEventID =  doc._id if doc.v is 'all'
        return @sendSuccess res, [] unless startEventID? and finishEventID? and filterEventID?

        queryParams = {$and: [
          {$or: [{e: startEventID}, {e: finishEventID}]},
          {f: filterEventID},
          {l: {$in: campaignLevelIDs}}
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

          completions = []
          for levelID of levelEventCounts
            completions.push
              level: levelStringIDSlugMap[levelID]
              started: levelEventCounts[levelID][startEventID]
              finished: levelEventCounts[levelID][finishEventID]
          completions.sort (a, b) -> orderedLevelSlugs.indexOf(a.level) - orderedLevelSlugs.indexOf(b.level)

          @campaignCompletionsCache[cacheKey] = completions
          @sendSuccess res, completions

    getLevelData = (campaignLevels) =>
      # 2. Get ordered level slugs and string ID to level slug mappping
      # Input:
      # campaignLevels - array of Level IDs

      queryParams = {original: {$in: campaignLevels}, "version.isLatestMajor": true, "version.isLatestMinor": true}
      Level.find(queryParams).exec (err, documents) =>
        if err? then return @sendDatabaseError res, err

        # Save original level ID and slug in array for sorting
        campaignOriginalSlugs = []
        for doc in documents
          campaignOriginalSlugs.push
            slug: doc.get('name').toLowerCase().replace new RegExp(' ', 'g'), '-'
            original: doc.get('original').toString()

        # Sort slugs against original levels from campaign
        campaignOriginalSlugs.sort (a, b) ->
          if campaignLevels.indexOf(a.original) < campaignLevels.indexOf(b.original) then -1 else 1

        # Lookup analytics string IDs for level slugs
        orderedLevelSlugs = []
        orderedLevelSlugs.push item.slug for item in campaignOriginalSlugs
        AnalyticsString.find({v: {$in: orderedLevelSlugs}}).exec (err, documents) =>
          if err? then return @sendDatabaseError res, err

          levelStringIDSlugMap = {}
          levelStringIDSlugMap[doc._id] = doc.v for doc in documents
          getCompletions orderedLevelSlugs, levelStringIDSlugMap

    # 1. Get campaign levels 
    Campaign.find({slug: campaignSlug}).exec (err, documents) =>
      if err? then return @sendDatabaseError res, err
      campaignLevels = []
      campaignLevels.push level for level of doc.get('levels') for doc in documents
      getLevelData campaignLevels

  getLevelCompletionsBySlug: (req, res) ->
    # Returns an array of per-day starts and finishes for given level
    # Parameters:
    # slug - level slug
    # startDay - Inclusive, optional, YYYYMMDD e.g. '20141214'
    # endDay - Exclusive, optional, YYYYMMDD e.g. '20141216'

    # TODO: Code is similar to getCampaignCompletionsBySlug

    levelSlug = req.query.slug or req.body.slug
    startDay = req.query.startDay or req.body.startDay
    endDay = req.query.endDay or req.body.endDay

    return @sendSuccess res, [] unless levelSlug?

    # log.warn "level_completions levelSlug='#{levelSlug}' startDay=#{startDay} endDay=#{endDay}"

    # Cache results in app server memory for 1 day
    @levelCompletionsCache ?= {}
    @levelCompletionsCachedSince ?= new Date()
    if (new Date()) - @levelCompletionsCachedSince > 86400 * 1000
      @levelCompletionsCache = {}
      @levelCompletionsCachedSince = new Date()
    cacheKey = levelSlug
    cacheKey += 's' + startDay if startDay?
    cacheKey += 'e' + endDay if endDay?
    return @sendSuccess res, levelCompletions if levelCompletions = @levelCompletionsCache[cacheKey]

    AnalyticsString.find({v: {$in: ['Started Level', 'Saw Victory', 'all', levelSlug]}}).exec (err, documents) =>
      if err? then return @sendDatabaseError res, err

      for doc in documents
        startEventID = doc._id if doc.v is 'Started Level'
        finishEventID = doc._id if doc.v is 'Saw Victory'
        filterEventID =  doc._id if doc.v is 'all'
        levelID = doc._id if doc.v is levelSlug
      return @sendSuccess res, [] unless startEventID? and finishEventID? and filterEventID? and levelID?

      queryParams = {$and: [{$or: [{e: startEventID}, {e: finishEventID}]},{f: filterEventID},{l: levelID}]}
      queryParams["$and"].push {d: {$gte: startDay}} if startDay?
      queryParams["$and"].push {d: {$lt: endDay}} if endDay?
      AnalyticsPerDay.find(queryParams).exec (err, documents) =>
        if err? then return @sendDatabaseError res, err

        dayEventCounts = {}
        for doc in documents
          day = doc.get('d')
          eventID = doc.get('e')
          count = doc.get('c')
          dayEventCounts[day] ?= {}
          dayEventCounts[day][eventID] = count

        completions = []
        for day of dayEventCounts
          for eventID of dayEventCounts[day]
            eventID = parseInt eventID
            started = dayEventCounts[day][eventID] if eventID is startEventID
            finished = dayEventCounts[day][eventID] if eventID is finishEventID
          completions.push
            created: day
            started: started
            finished: finished

        @levelCompletionsCache[cacheKey] = completions
        @sendSuccess res, completions

module.exports = new AnalyticsPerDayHandler()
