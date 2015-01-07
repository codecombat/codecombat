AnalyticsLogEvent = require './AnalyticsLogEvent'
Campaign = require '../campaigns/Campaign'
Level = require '../levels/Level'
Handler = require '../commons/Handler'
log = require 'winston'

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

  getByRelationship: (req, res, args...) ->
    return @getLevelCompletionsBySlug(req, res) if args[1] is 'level_completions'
    return @getCampaignCompletionsBySlug(req, res) if args[1] is 'campaign_completions'
    super(arguments...)

  getLevelCompletionsBySlug: (req, res) ->
    # Returns an array of per-day level starts and finishes
    # Parameters:
    # slug - level slug
    # startDay - Inclusive, optional, e.g. '2014-12-14'
    # endDay - Exclusive, optional, e.g. '2014-12-16'

    # TODO: An uncached call takes about 15s locally
    # TODO: Use unique users

    levelSlug = req.query.slug or req.body.slug
    startDay = req.query.startDay or req.body.startDay
    endDay = req.query.endDay or req.body.endDay

    return @sendSuccess res, [] unless levelSlug?

    # Cache results for 1 day
    @levelCompletionsCache ?= {}
    @levelCompletionsCachedSince ?= new Date()
    if (new Date()) - @levelCompletionsCachedSince > 86400 * 1000  # Dumb cache expiration
      @levelCompletionsCache = {}
      @levelCompletionsCachedSince = new Date()
    cacheKey = levelSlug
    cacheKey += 's' + startDay if startDay?
    cacheKey += 'e' + endDay if endDay?
    return @sendSuccess res, levelCompletions if levelCompletions = @levelCompletionsCache[cacheKey]

    # Build query
    match = {$match: {$and: [{$or: [{"event" : 'Started Level'}, {"event" : 'Saw Victory'}]}]}}
    match["$match"]["$and"].push created: {$gte: new Date(startDay + "T00:00:00.000Z")} if startDay?
    match["$match"]["$and"].push created: {$lt: new Date(endDay + "T00:00:00.000Z")} if endDay?
    project = {"$project": {"_id": 0, "event": 1, "level": {$ifNull: ["$properties.level", "$properties.levelID"]}, "created": {"$concat": [{"$substr":  ["$created", 0, 4]}, "-", {"$substr":  ["$created", 5, 2]}, "-", {"$substr" :  ["$created", 8, 2]}]}}}
    group = {"$group": {"_id": {"event": "$event", "created": "$created", "level": "$level"}, "count": {"$sum": 1}}}
    query = AnalyticsLogEvent.aggregate match, project, group

    query.exec (err, data) =>
      if err? then return @sendDatabaseError res, err
      
      # Build per-level-day started and finished counts
      levelDateMap = {}
      for item in data
        created = item._id.created
        event = item._id.event
        level = item._id.level
        continue unless level?
        # 'Started Level' event uses level slug, 'Saw Victory' event uses level name with caps and spaces.
        level = level.toLowerCase().replace new RegExp(' ', 'g'), '-' if event is 'Saw Victory'

        levelDateMap[level] ?= {}
        levelDateMap[level][created] ?= {}
        levelDateMap[level][created] ?= {}
        if event is 'Saw Victory'
          levelDateMap[level][created]['finished'] = item.count
        else
          levelDateMap[level][created]['started'] = item.count
          
      # Build list of level completions
      # Cache every level, since we had to grab all this data anyway
      completions = {}
      for level of levelDateMap
        completions[level] = []
        for created, item of levelDateMap[level]
          completions[level].push 
            level: level
            created: created
            started: item.started
            finished: item.finished
        cacheKey = level
        cacheKey += 's' + startDay if startDay?
        cacheKey += 'e' + endDay if endDay?
        @levelCompletionsCache[cacheKey] = completions[level]
      @sendSuccess res, completions[levelSlug]

  getCampaignCompletionsBySlug: (req, res) ->
    # Returns a dictionary of per-campaign level starts, finishes, and drop-offs
    # Drop-off: last started or finished level event
    # Parameters:
    # slugs - array of campaign slugs
    # startDay - Inclusive, optional, e.g. '2014-12-14'
    # endDay - Exclusive, optional, e.g. '2014-12-16'

    # TODO: Must be a better way to organize this series of 3 database calls (campaigns, levels, analytics)
    # TODO: An uncached call can take over 30s locally
    # TODO: Returns all the campaigns
    # TODO: Calculate overall campaign stats
    # TODO: Assumes db campaign levels are in progression order.  Should build this based on actual progression.

    campaignSlug = req.query.slug or req.body.slug
    startDay = req.query.startDay or req.body.startDay
    endDay = req.query.endDay or req.body.endDay

    return @sendSuccess res, [] unless campaignSlug?

    # Cache results for 1 day
    @campaignDropOffsCache ?= {}
    @campaignDropOffsCachedSince ?= new Date()
    if (new Date()) - @campaignDropOffsCachedSince > 86400 * 1000  # Dumb cache expiration
      @campaignDropOffsCache = {}
      @campaignDropOffsCachedSince = new Date()
    cacheKey = campaignSlug
    cacheKey += 's' + startDay if startDay?
    cacheKey += 'e' + endDay if endDay?
    return @sendSuccess res, campaignDropOffs if campaignDropOffs = @campaignDropOffsCache[cacheKey]

    getCompletions = (campaigns) =>
      # Calculate campaign drop off rates
      # Input:
      # campaigns - per-campaign dictionary of ordered level slugs

      queryParams = {$and: [{$or: [ {"event" : 'Started Level'}, {"event" : 'Saw Victory'}]}]}
      queryParams["$and"].push created: {$gte: new Date(startDay + "T00:00:00.000Z")} if startDay?
      queryParams["$and"].push created: {$lt: new Date(endDay + "T00:00:00.000Z")} if endDay?

      AnalyticsLogEvent.find(queryParams).select('created event properties user').exec (err, data) =>
        if err? then return @sendDatabaseError res, err

        # Bucketize events by user
        userProgression = {}
        userLevelEventMap = {} # Only want unique users per-level/event
        for item in data
          created = item.get('created')
          event = item.get('event')
          if event is 'Saw Victory'
            level = item.get('properties.level').toLowerCase().replace new RegExp(' ', 'g'), '-'
          else
            level = item.get('properties.levelID')
          continue unless level?
          user = item.get('user')
          userLevelEventMap[user] ?= {}
          userLevelEventMap[user][level] ?= {}
          unless userLevelEventMap[user][level][event]
            userLevelEventMap[user][level][event] = true
            userProgression[user] ?= []
            userProgression[user].push
              created: created
              event: event
              level: level

        # Order user progression by created
        for user of userProgression
          userProgression[user].sort (a,b) -> if a.created < b.created then return -1 else 1

        # Per-level start/drop/finish/drop
        levelProgression = {}
        for user of userProgression
          for i in [0...userProgression[user].length]
            event = userProgression[user][i].event
            level = userProgression[user][i].level
            levelProgression[level] ?=
              started: 0
              startDropped: 0
              finished: 0
              finishDropped: 0
            if event is 'Started Level'
              levelProgression[level].started++
              levelProgression[level].startDropped++ if i is userProgression[user].length - 1
            else if event is 'Saw Victory'
              levelProgression[level].finished++
              levelProgression[level].finishDropped++ if i is userProgression[user].length - 1

        # Put in campaign order
        completions = {}
        for level of levelProgression
          for campaign of campaigns
            if level in campaigns[campaign]
              started = levelProgression[level].started
              startDropped = levelProgression[level].startDropped
              finished = levelProgression[level].finished
              finishDropped = levelProgression[level].finishDropped
              completions[campaign] ?=
                levels: []
                # overall:
                #   started: 0,
                #   startDropped: 0,
                #   finished: 0,
                #   finishDropped: 0
              completions[campaign].levels.push
                level: level
                started: started
                startDropped: startDropped
                finished: finished
                finishDropped: finishDropped
              break

        # Sort level data by campaign order
        for campaign of completions
          completions[campaign].levels.sort (a, b) ->
            if campaigns[campaign].indexOf(a.level) < campaigns[campaign].indexOf(b.level) then return -1 else 1

        # Return all campaign data for simplicity
        # Cache other individual campaigns too, since we have them
        @campaignDropOffsCache[cacheKey] = completions
        for campaign of completions
          cacheKey = campaign
          cacheKey += 's' + startDay if startDay?
          cacheKey += 'e' + endDay if endDay?
          @campaignDropOffsCache[cacheKey] = completions
        @sendSuccess res, completions

    getLevelData = (campaigns, campaignLevelIDs) =>
      # Get level data and replace levelIDs with level slugs in campaigns
      # Input:
      # campaigns - per-campaign dictionary of ordered levelIDs
      # campaignLevelIDs - dictionary of all campaign levelIDs
      # Output:
      # campaigns - per-campaign dictionary of ordered level slugs

      Level.find({original: {$in: campaignLevelIDs}, "version.isLatestMajor": true, "version.isLatestMinor": true}).exec (err, documents) =>
        if err? then return @sendDatabaseError res, err

        levelSlugMap = {}
        for doc in documents
          levelID = doc.get('original')
          levelSlug = doc.get('name').toLowerCase().replace new RegExp(' ', 'g'), '-'
          levelSlugMap[levelID] = levelSlug

        # Replace levelIDs with level slugs
        for campaign of campaigns
          mapFn = (item) -> levelSlugMap[item]
          campaigns[campaign] = _.map campaigns[campaign], mapFn, @

        getCompletions campaigns

    getCampaignData = () =>
      # Get campaign data 
      # Output:
      # campaigns - per-campaign dictionary of ordered levelIDs
      # campaignLevelIDs - dictionary of all campaign levelIDs

      Campaign.find().exec (err, documents) =>
        if err? then return @sendDatabaseError res, err

        campaigns = {}
        levelCampaignMap = {}
        campaignLevelIDs = []
        for doc in documents
          campaignSlug = doc.get('slug')
          levels = doc.get('levels')
          campaigns[campaignSlug] = []
          levelCampaignMap[campaignSlug] = {}
          for levelID of levels
            campaigns[campaignSlug].push levelID
            campaignLevelIDs.push levelID
            levelCampaignMap[levelID] = campaignSlug

        getLevelData campaigns, campaignLevelIDs

    getCampaignData()

module.exports = new AnalyticsLogEventHandler()
