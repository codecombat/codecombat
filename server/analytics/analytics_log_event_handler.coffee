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
    super(arguments...)

  getLevelCompletionsBySlugs: (req, res) ->
    # Returns an array of per-day level starts and finishes
    # Parameters:
    # slugs - array of level slugs
    # startDay - Inclusive, optional, e.g. '2014-12-14'
    # endDay - Exclusive, optional, e.g. '2014-12-16'
    
    # TODO: An uncached call takes about 15s

    levelSlugs = req.query.slugs or req.body.slugs
    startDay = req.query.startDay or req.body.startDay
    endDay = req.query.endDay or req.body.endDay

    return @sendSuccess res, [] unless levelSlugs?

    # Cache results for 1 day
    @levelCompletionsCache ?= {}
    @levelCompletionsCachedSince ?= new Date()
    if (new Date()) - @levelCompletionsCachedSince > 86400 * 1000  # Dumb cache expiration
      @levelCompletionsCache = {}
      @levelCompletionsCacheSince = new Date()
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

module.exports = new AnalyticsLogEventHandler()
