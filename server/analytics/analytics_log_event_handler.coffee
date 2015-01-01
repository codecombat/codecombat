AnalyticsLogEvent = require './AnalyticsLogEvent'
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
    return @getLevelCompletionsBySlugs(req, res) if args[1] is 'level_completions'
    return @getCampaignDropOffs(req, res) if args[1] is 'campaign_drop_offs'
    super(arguments...)

  getLevelCompletionsBySlugs: (req, res) ->
    # Returns an array of per-day level starts and finishes
    # Parameters:
    # slugs - array of level slugs
    # startDay - Inclusive, optional, e.g. '2014-12-14'
    # endDay - Exclusive, optional, e.g. '2014-12-16'

    # TODO: An uncached call takes about 15s locally

    levelSlugs = req.query.slugs or req.body.slugs
    startDay = req.query.startDay or req.body.startDay
    endDay = req.query.endDay or req.body.endDay

    return @sendSuccess res, [] unless levelSlugs?

    # Cache results for 1 day
    @levelCompletionsCache ?= {}
    @levelCompletionsCachedSince ?= new Date()
    if (new Date()) - @levelCompletionsCachedSince > 86400 * 1000  # Dumb cache expiration
      @levelCompletionsCache = {}
      @levelCompletionsCachedSince = new Date()
    cacheKey = levelSlugs.join(',')
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
        continue unless level in levelSlugs

        levelDateMap[level] ?= {}
        levelDateMap[level][created] ?= {}
        levelDateMap[level][created] ?= {}
        if event is 'Saw Victory'
          levelDateMap[level][created]['finished'] = item.count
        else
          levelDateMap[level][created]['started'] = item.count
          
      # Build list of level completions
      completions = []
      for level of levelDateMap
        for created, item of levelDateMap[level]
          completions.push 
            level: level
            created: created
            started: item.started
            finished: item.finished
      @levelCompletionsCache[cacheKey] = completions
      @sendSuccess res, completions

  getCampaignDropOffs: (req, res) ->
    # Returns a dictionary of per-campaign level start and finish drop-offs
    # Drop-off: last started or finished level event
    # Parameters:
    # slugs - array of campaign slugs
    # startDay - Inclusive, optional, e.g. '2014-12-14'
    # endDay - Exclusive, optional, e.g. '2014-12-16'

    # TODO: Read per-campaign level progression data from a legit source
    # TODO: An uncached call can take over 30s locally
    # TODO: Returns all the campaigns
    # TODO: Calculate overall campaign stats

    campaignSlugs = req.query.slugs or req.body.slugs
    startDay = req.query.startDay or req.body.startDay
    endDay = req.query.endDay or req.body.endDay

    return @sendSuccess res, [] unless campaignSlugs?

    # Cache results for 1 day
    @campaignDropOffsCache ?= {}
    @campaignDropOffsCachedSince ?= new Date()
    if (new Date()) - @campaignDropOffsCachedSince > 86400 * 1000  # Dumb cache expiration
      @campaignDropOffsCache = {}
      @campaignDropOffsCachedSince = new Date()
    cacheKey = campaignSlugs.join(',')
    cacheKey += 's' + startDay if startDay?
    cacheKey += 'e' + endDay if endDay?
    return @sendSuccess res, campaignDropOffs if campaignDropOffs = @campaignDropOffsCache[cacheKey]

    queryParams = {$and: [{$or: [ {"event" : 'Started Level'}, {"event" : 'Saw Victory'}]}]}
    queryParams["$and"].push created: {$gte: new Date(startDay + "T00:00:00.000Z")} if startDay?
    queryParams["$and"].push created: {$lt: new Date(endDay + "T00:00:00.000Z")} if endDay?

    AnalyticsLogEvent.find(queryParams).select('created event properties user').exec (err, data) =>
      if err? then return @sendDatabaseError res, err

      # Bucketize events by user
      userProgression = {}
      for item in data
        created = item.get('created')
        event = item.get('event')
        if event is 'Saw Victory'
          level = item.get('properties.level').toLowerCase().replace new RegExp(' ', 'g'), '-'
        else
          level = item.get('properties.levelID')
        continue unless level?
        user = item.get('user')
        userProgression[user] ?= []
        userProgression[user].push
          created: created
          event: event
          level: level
      
      # Order user progression by created
      for user in userProgression
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
      campaignRates = {}
      for level of levelProgression
        for campaign of campaigns
          if level in campaigns[campaign]
            started = levelProgression[level].started
            startDropped = levelProgression[level].startDropped
            finished = levelProgression[level].finished
            finishDropped = levelProgression[level].finishDropped
            campaignRates[campaign] ?=
              levels: []
              # overall:
              #   started: 0,
              #   startDropped: 0,
              #   finished: 0,
              #   finishDropped: 0
            campaignRates[campaign].levels.push
              level: level
              started: started
              startDropped: startDropped
              finished: finished
              finishDropped: finishDropped
            break
      
      # Sort level data by campaign order
      for campaign of campaignRates
        campaignRates[campaign].levels.sort (a, b) ->
          if campaigns[campaign].indexOf(a.level) < campaigns[campaign].indexOf(b.level) then return -1 else 1

      # Return all campaign data for simplicity
      # Cache other individual campaigns too, since we have them
      @campaignDropOffsCache[cacheKey] = campaignRates
      for campaign of campaignRates
        cacheKey = campaign
        cacheKey += 's' + startDay if startDay?
        cacheKey += 'e' + endDay if endDay?
        @campaignDropOffsCache[cacheKey] = campaignRates
      @sendSuccess res, campaignRates

# Copied from WorldMapView
dungeonLevels = [
  'dungeons-of-kithgard',
  'gems-in-the-deep',
  'shadow-guard',
  'kounter-kithwise',
  'crawlways-of-kithgard',
  'forgetful-gemsmith',
  'true-names',
  'favorable-odds',
  'the-raised-sword',
  'haunted-kithmaze',
  'riddling-kithmaze',
  'descending-further',
  'the-second-kithmaze',
  'dread-door',
  'known-enemy',
  'master-of-names',
  'lowly-kithmen',
  'closing-the-distance',
  'tactical-strike',
  'the-final-kithmaze',
  'the-gauntlet',
  'kithgard-gates',
  'cavern-survival'
];

forestLevels = [
  'defense-of-plainswood',
  'winding-trail',
  'patrol-buster',
  'endangered-burl',
  'village-guard',
  'thornbush-farm',
  'back-to-back',
  'ogre-encampment',
  'woodland-cleaver',
  'shield-rush',
  'peasant-protection',
  'munchkin-swarm',
  'munchkin-harvest',
  'swift-dagger',
  'shrapnel',
  'arcane-ally',
  'touch-of-death',
  'bonemender',
  'coinucopia',
  'copper-meadows',
  'drop-the-flag',
  'deadly-pursuit',
  'rich-forager',
  'siege-of-stonehold',
  'multiplayer-treasure-grove',
  'dueling-grounds'
];

desertLevels = [
  'the-dunes',
  'the-mighty-sand-yak',
  'oasis',
  'sarven-road',
  'sarven-gaps',
  'thunderhooves',
  'medical-attention',
  'minesweeper',
  'sarven-sentry',
  'keeping-time',
  'hoarding-gold',
  'decoy-drill',
  'yakstraction',
  'sarven-brawl',
  'desert-combat',
  'dust',
  'mirage-maker',
  'sarven-savior',
  'odd-sandstorm'
];

campaigns = {
  'dungeon': dungeonLevels,
  'forest': forestLevels,
  'desert': desertLevels
}

module.exports = new AnalyticsLogEventHandler()
