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
    req.user?.isAdmin() or false

  getByRelationship: (req, res, args...) ->
    return @sendForbiddenError res unless @hasAccess req
    return @getActiveUsers(req, res) if args[1] is 'active_users'
    return @getCampaignCompletionsBySlug(req, res) if args[1] is 'campaign_completions'
    return @getLevelCompletionsBySlug(req, res) if args[1] is 'level_completions'
    return @getLevelDropsBySlugs(req, res) if args[1] is 'level_drops'
    return @getLevelHelpsBySlugs(req, res) if args[1] is 'level_helps'
    return @getLevelSubscriptionsBySlugs(req, res) if args[1] is 'level_subscriptions'
    super(arguments...)

  getActiveUsers: (req, res) ->
    AnalyticsString.find({v: {$in: ['Daily Active Users', 'Monthly Active Users']}}).exec (err, documents) =>
      return @sendDatabaseError(res, err) if err
      for doc in documents
        dailyID = doc._id if doc.v is 'Daily Active Users'
        monthlyID = doc._id if doc.v is 'Monthly Active Users'
      return @sendSuccess res, [] unless dailyID? and monthlyID?

      AnalyticsPerDay.find({e: {$in: [dailyID, monthlyID]}}).exec (err, documents) =>
        return @sendDatabaseError(res, err) if err
        dayCountsMap = {}
        for doc in documents
          dayCountsMap[doc.d] ?= {}
          dayCountsMap[doc.d]['dailyCount'] = doc.c if doc.e is dailyID
          dayCountsMap[doc.d]['monthlyCount'] = doc.c if doc.e is monthlyID
        activeUsers = []
        for key, val of dayCountsMap
          data = day: key
          data.dailyCount = val.dailyCount if val.dailyCount
          data.monthlyCount = val.monthlyCount if val.monthlyCount
          activeUsers.push data
        @sendSuccess(res, activeUsers)

  getCampaignCompletionsBySlug: (req, res) ->
    # Send back an ordered array of level per-day starts and finishes
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
    return @sendSuccess res, completions if completions = @campaignCompletionsCache[cacheKey]

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
            levelEventCounts[doc.l][doc.d] ?= {}
            levelEventCounts[doc.l][doc.d][doc.e] ?= 0
            levelEventCounts[doc.l][doc.d][doc.e] += doc.c

          completions = []
          for levelID of levelEventCounts
            days = {}
            for day of levelEventCounts[levelID]
              days[day] =
                started: levelEventCounts[levelID][day][startEventID] ? 0
                finished: levelEventCounts[levelID][day][finishEventID] ? 0
            completions.push
              level: levelStringIDSlugMap[levelID]
              days: days
          completions.sort (a, b) -> orderedLevelSlugs.indexOf(a.level) - orderedLevelSlugs.indexOf(b.level)

          @campaignCompletionsCache[cacheKey] = completions
          @sendSuccess res, completions

    getLevelData = (campaignLevels) =>
      # 2. Get ordered level slugs and string ID to level slug mapping
      # Input:
      # campaignLevels - array of Level IDs

      queryParams = {original: {$in: campaignLevels}, "version.isLatestMajor": true, "version.isLatestMinor": true}
      Level.find(queryParams).exec (err, documents) =>
        if err? then return @sendDatabaseError res, err

        # Save original level ID and slug in array for sorting
        campaignOriginalSlugs = []
        for doc in documents
          campaignOriginalSlugs.push
            slug: _.str.slugify(doc.get('name'))
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

  getLevelDropsBySlugs: (req, res) ->
    # Send back an array of level/drops
    # Drops - Number of unique users for which this was the last level they played
    # Parameters:
    # slugs - level slugs
    # startDay - Inclusive, optional, YYYYMMDD e.g. '20141214'
    # endDay - Exclusive, optional, YYYYMMDD e.g. '20141216'

    levelSlugs = req.query.slugs or req.body.slugs
    startDay = req.query.startDay or req.body.startDay
    endDay = req.query.endDay or req.body.endDay

    # log.warn "level_drops levelSlugs='#{levelSlugs}' startDay=#{startDay} endDay=#{endDay}"

    return @sendSuccess res, [] unless levelSlugs?

    # Cache results in app server memory for 1 day
    @levelDropsCache ?= {}
    @levelDropsCachedSince ?= new Date()
    if (new Date()) - @levelDropsCachedSince > 86400 * 1000
      @levelDropsCache = {}
      @levelDropsCachedSince = new Date()
    cacheKey = levelSlugs.join ''
    cacheKey += 's' + startDay if startDay?
    cacheKey += 'e' + endDay if endDay?
    return @sendSuccess res, drops if drops = @levelDropsCache[cacheKey]

    AnalyticsString.find({v: {$in: ['User Dropped', 'all'].concat(levelSlugs)}}).exec (err, documents) =>
      if err? then return @sendDatabaseError res, err

      levelStringIDSlugMap = {}
      for doc in documents
        droppedEventID = doc._id if doc.v is 'User Dropped'
        filterEventID =  doc._id if doc.v is 'all'
        levelStringIDSlugMap[doc._id] = doc.v if doc.v in levelSlugs

      return @sendSuccess res, [] unless droppedEventID? and filterEventID?

      queryParams = {$and: [
        {e: droppedEventID},
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

        drops = []
        for levelID of levelEventCounts
          drops.push
            level: levelStringIDSlugMap[levelID]
            dropped: levelEventCounts[levelID][droppedEventID] ? 0

        @levelDropsCache[cacheKey] = drops
        @sendSuccess res, drops

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
          started = 0
          finished = 0
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

  getLevelHelpsBySlugs: (req, res) ->
    # Send back an array of per-day level help buttons clicked and videos started
    # Parameters:
    # slugs - level slugs
    # startDay - Inclusive, optional, YYYYMMDD e.g. '20141214'
    # endDay - Exclusive, optional, YYYYMMDD e.g. '20141216'

    levelSlugs = req.query.slugs or req.body.slugs
    startDay = req.query.startDay or req.body.startDay
    endDay = req.query.endDay or req.body.endDay

    # log.warn "level_helps levelSlugs='#{levelSlugs}' startDay=#{startDay} endDay=#{endDay}"

    return @sendSuccess res, [] unless levelSlugs?

    # Cache results in app server memory for 1 day
    @levelHelpsCache ?= {}
    @levelHelpsCachedSince ?= new Date()
    if (new Date()) - @levelHelpsCachedSince > 86400 * 1000
      @levelHelpsCache = {}
      @levelHelpsCachedSince = new Date()
    cacheKey = levelSlugs.join ''
    cacheKey += 's' + startDay if startDay?
    cacheKey += 'e' + endDay if endDay?
    return @sendSuccess res, helps if helps = @levelHelpsCache[cacheKey]

    findQueryParams = {v: {$in: ['Problem alert help clicked', 'Spell palette help clicked', 'Start help video', 'all'].concat(levelSlugs)}}
    AnalyticsString.find(findQueryParams).exec (err, documents) =>
      if err? then return @sendDatabaseError res, err

      levelStringIDSlugMap = {}
      for doc in documents
        alertHelpEventID = doc._id if doc.v is 'Problem alert help clicked'
        palettteHelpEventID = doc._id if doc.v is 'Spell palette help clicked'
        videoHelpEventID = doc._id if doc.v is 'Start help video'
        filterEventID =  doc._id if doc.v is 'all'
        levelStringIDSlugMap[doc._id] = doc.v if doc.v in levelSlugs

      return @sendSuccess res, [] unless alertHelpEventID? and palettteHelpEventID? and videoHelpEventID? and filterEventID?

      queryParams = {$and: [
        {e: {$in: [alertHelpEventID, palettteHelpEventID, videoHelpEventID]}},
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
          levelEventCounts[doc.l][doc.d] ?= {}
          levelEventCounts[doc.l][doc.d][doc.e] ?= 0
          levelEventCounts[doc.l][doc.d][doc.e] += doc.c

        helps = []
        for levelID of levelEventCounts
          for day of levelEventCounts[levelID]
            alertHelps = 0
            paletteHelps = 0
            videoStarts = 0
            for eventID of levelEventCounts[levelID][day]
              alertHelps = levelEventCounts[levelID][day][eventID] if parseInt(eventID) is alertHelpEventID
              paletteHelps = levelEventCounts[levelID][day][eventID] if parseInt(eventID) is palettteHelpEventID
              videoStarts = levelEventCounts[levelID][day][eventID] if parseInt(eventID) is videoHelpEventID
            helps.push
              level: levelStringIDSlugMap[levelID]
              day: day
              alertHelps: alertHelps
              paletteHelps: paletteHelps
              videoStarts: videoStarts

        @levelHelpsCache[cacheKey] = helps
        @sendSuccess res, helps


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

module.exports = new AnalyticsPerDayHandler()
