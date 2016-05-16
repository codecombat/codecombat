log = require 'winston'
mongoose = require 'mongoose'
utils = require '../lib/utils'
AnalyticsLogEvent = require './../models/AnalyticsLogEvent'
Campaign = require '../models/Campaign'
Level = require '../models/Level'
Handler = require '../commons/Handler'

class AnalyticsLogEventHandler extends Handler
  modelClass: AnalyticsLogEvent
  jsonSchema: require '../../app/schemas/models/analytics_log_event'
  editableProperties: [
    'e'
    'p'
    'event'
    'properties'
  ]

  hasAccess: (req) ->
    req.method in ['POST'] or req.user?.isAdmin()

  makeNewInstance: (req) ->
    instance = super(req)
    instance.set('u', req.user._id)
    # TODO: Remove 'user' after we stop querying for it (probably 30 days, ~2/16/15)
    instance.set('user', req.user._id)
    instance

  getByRelationship: (req, res, args...) ->
    return @logEvent(req, res) if args[1] is 'log_event'
    # TODO: Remove these APIs
    # return @getLevelCompletionsBySlug(req, res) if args[1] is 'level_completions'
    # return @getCampaignCompletionsBySlug(req, res) if args[1] is 'campaign_completions'
    super(arguments...)

  logEvent: (req, res) ->
    # Converts strings to string IDs where possible, and logs the event
    user = req.user?._id
    event = req.query.event or req.body.event
    properties = req.query.properties or req.body.properties
    @sendSuccess res # Return request immediately
    AnalyticsLogEvent.logEvent user, event, properties

  getLevelCompletionsBySlug: (req, res) ->
    # Returns an array of per-day level starts and finishes
    # Parameters:
    # slug - level slug
    # startDay - Inclusive, optional, e.g. '2014-12-14'
    # endDay - Exclusive, optional, e.g. '2014-12-16'

    # TODO: An uncached call can take over 50s locally
    # TODO: mapReduce() was slower than find()

    levelSlug = req.query.slug or req.body.slug
    startDay = req.query.startDay or req.body.startDay
    endDay = req.query.endDay or req.body.endDay

    return @sendSuccess res, [] unless levelSlug?

    # log.warn "level_completions levelSlug='#{levelSlug}' startDay=#{startDay} endDay=#{endDay}"

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

    levelDateMap = {}

    # Build query
    queryParams = {$and: [
      {$or: [{"event" : 'Started Level'}, {"event" : 'Saw Victory'}]}
    ]}
    queryParams["$and"].push _id: {$gte: utils.objectIdFromTimestamp(startDay + "T00:00:00.000Z")} if startDay?
    queryParams["$and"].push _id: {$lt: utils.objectIdFromTimestamp(endDay + "T00:00:00.000Z")} if endDay?

    # Query stream is better for large results
    # http://mongoosejs.com/docs/api.html#query_Query-stream
    stream = AnalyticsLogEvent.find(queryParams).select('created event properties user').stream()
    stream.on 'data', (item) =>
      # Build per-level-day started and finished counts
      created = item.get('created').toISOString().substring(0, 10)
      event = item.get('event')
      properties = item.get('properties')
      if properties.level? then level = properties.level.toLowerCase().replace new RegExp(' ', 'g'), '-'
      else if properties.levelID? then level = properties.levelID
      else return
      user = item.get('user')

      # log.warn "level_completions data " + " " + created + " " + event + " " + level

      levelDateMap[level] ?= {}
      levelDateMap[level][created] ?= {}
      levelDateMap[level][created]['finished'] ?= {}
      levelDateMap[level][created]['started'] ?= {}
      if event is 'Saw Victory' then levelDateMap[level][created]['finished'][user] = true
      else levelDateMap[level][created]['started'][user] = true
    .on 'error', (err) =>
      return @sendDatabaseError res, err
    .on 'close', () =>
      # Build list of level completions
      # Cache every level, since we had to grab all this data anyway
      completions = {}
      for level of levelDateMap
        completions[level] = []
        for created, item of levelDateMap[level]
          completions[level].push
            level: level
            created: created
            started: Object.keys(item.started).length
            finished: Object.keys(item.finished).length
        cacheKey = level
        cacheKey += 's' + startDay if startDay?
        cacheKey += 'e' + endDay if endDay?
        @levelCompletionsCache[cacheKey] = completions[level]
      unless levelSlug of completions then completions[levelSlug] = []
      @sendSuccess res, completions[levelSlug]

  getCampaignCompletionsBySlug: (req, res) ->
    # Returns a dictionary of per-campaign level starts, finishes, and drop-offs
    # Drop-off: last started or finished level event
    # Parameters:
    # slugs - array of campaign slugs
    # startDay - Inclusive, optional, e.g. '2014-12-14'
    # endDay - Exclusive, optional, e.g. '2014-12-16'

    # TODO: Must be a better way to organize this series of database calls (campaigns, levels, analytics)
    # TODO: An uncached call can take over 50s locally
    # TODO: Returns all the campaigns
    # TODO: Calculate overall campaign stats
    # TODO: Assumes db campaign levels are in progression order.  Should build this based on actual progression.
    # TODO: Remove earliest duplicate event so our dropped counts will be more accurate.

    campaignSlug = req.query.slug or req.body.slug
    startDay = req.query.startDay or req.body.startDay
    endDay = req.query.endDay or req.body.endDay

    # log.warn "campaign_completions campaignSlug='#{campaignSlug}' startDay=#{startDay} endDay=#{endDay}"

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

    getCompletions = (campaigns, userProgression) =>
      # Calculate campaign drop off rates
      # Input:
      # campaigns - per-campaign dictionary of ordered level slugs
      # userProgression - per-user event lists

      # Remove duplicate user events
      for user of userProgression
        userProgression[user] = _.uniq userProgression[user], false, (val, index, arr) -> val.event + val.level

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
      unless campaignSlug of completions then completions[campaignSlug] = levels: []
      @sendSuccess res, completions

    getUserEventData = (campaigns) =>
      # Gather user start and finish event data
      # Input:
      # campaigns - per-campaign dictionary of ordered level slugs
      # Output:
      # userProgression - per-user event lists

      userProgression = {}

      queryParams = {$and: [{$or: [ {"event" : 'Started Level'}, {"event" : 'Saw Victory'}]}]}
      queryParams["$and"].push _id: {$gte: utils.objectIdFromTimestamp(startDay + "T00:00:00.000Z")} if startDay?
      queryParams["$and"].push _id: {$lt: utils.objectIdFromTimestamp(endDay + "T00:00:00.000Z")} if endDay?

      # Query stream is better for large results
      # http://mongoosejs.com/docs/api.html#query_Query-stream
      stream = AnalyticsLogEvent.find(queryParams).select('created event properties user').stream()
      stream.on 'data', (item) =>
        created = item.get('created')
        event = item.get('event')
        if event is 'Saw Victory'
          level = item.get('properties.level').toLowerCase().replace new RegExp(' ', 'g'), '-'
        else
          level = item.get('properties.levelID')
        return unless level?
        user = item.get('user')
        userProgression[user] ?= []
        userProgression[user].push
          created: created
          event: event
          level: level
      .on 'error', (err) =>
        return @sendDatabaseError res, err
      .on 'close', () =>
        getCompletions campaigns, userProgression

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

        getUserEventData campaigns

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
          slug = doc.get('slug')
          levels = doc.get('levels')
          campaigns[slug] = []
          levelCampaignMap[slug] = {}
          for levelID of levels
            campaigns[slug].push levelID
            campaignLevelIDs.push levelID
            levelCampaignMap[levelID] = slug

        getLevelData campaigns, campaignLevelIDs

    getCampaignData()

module.exports = new AnalyticsLogEventHandler()
