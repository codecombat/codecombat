wrap = require 'co-express'
AnalyticsString = require './../models/AnalyticsString'
AnalyticsPerDay = require './../models/AnalyticsPerDay'
Campaign = require '../models/Campaign'
Level = require '../models/Level'

getActiveClasses = wrap (req, res) ->
  events = [
    'Active classes paid',
    'Active classes trial',
    'Active classes free'
  ]

  documents = yield AnalyticsString.find({v: {$in: events}})
  eventIDs = []
  eventStringMap = {}
  for doc in documents
    eventStringMap[doc._id.valueOf()] = doc.v
    eventIDs.push doc._id
  return res.send([]) unless eventIDs.length is events.length

  documents = yield AnalyticsPerDay.find({e: {$in: eventIDs}})
  dayCountsMap = {}
  for doc in documents
    dayCountsMap[doc.d] ?= {}
    dayCountsMap[doc.d][eventStringMap[doc.e.valueOf()]] = doc.c
  activeClasses = []
  for key, val of dayCountsMap
    activeClasses.push day: key, classes: dayCountsMap[key]
  res.send(activeClasses)


getActiveUsers = wrap (req, res) ->
  events = ['DAU classroom paid', 'DAU classroom trial', 'DAU classroom free', 'DAU campaign paid', 'DAU campaign free',
            'MAU classroom paid', 'MAU classroom trial', 'MAU classroom free', 'MAU campaign paid', 'MAU campaign free']
  documents = yield AnalyticsString.find({v: {$in: events}})
  eventIDs = []
  eventStringMap = {}
  for doc in documents
    eventIDs.push(doc._id)
    eventStringMap[doc._id] = doc.v

  documents = yield AnalyticsPerDay.find({e: {$in: eventIDs}})
  dayCountsMap = {}
  for doc in documents
    dayCountsMap[doc.d] ?= {}
    dayCountsMap[doc.d][eventStringMap[doc.e]] = doc.c
  activeUsers = ({day: day, events: eventCountMap} for day, eventCountMap of dayCountsMap)
  res.send(activeUsers)


getCampaignCompletionsBySlug = wrap (req, res) ->
  # Send back an ordered array of level per-day starts and finishes
  # Parameters:
  # slug - campaign slug
  # startDay - Inclusive, optional, YYYYMMDD e.g. '20141214'
  # endDay - Exclusive, optional, YYYYMMDD e.g. '20141216'

  campaignSlug = req.query.slug or req.body.slug
  startDay = req.query.startDay or req.body.startDay
  endDay = req.query.endDay or req.body.endDay

  # log.warn "campaign_completions campaignSlug='#{campaignSlug}' startDay=#{startDay} endDay=#{endDay}"

  return res.send([]) unless campaignSlug?

  # Cache results in app server memory for 1 day
  @campaignCompletionsCache ?= {}
  @campaignCompletionsCachedSince ?= new Date()
  if (new Date()) - @campaignCompletionsCachedSince > 86400 * 1000
    @campaignCompletionsCache = {}
    @campaignCompletionsCachedSince = new Date()
  cacheKey = campaignSlug
  cacheKey += 's' + startDay if startDay?
  cacheKey += 'e' + endDay if endDay?
  return res.send(completions) if completions = @campaignCompletionsCache[cacheKey]

  
  # 1. Get campaign levels
  campaigns = yield Campaign.find({slug: campaignSlug})
  campaignLevels = []
  campaignLevels.push level for level of doc.get('levels') for doc in campaigns

  
  # 2. Get ordered level slugs and string ID to level slug mapping
  # campaignLevels - array of Level IDs

  queryParams = {original: {$in: campaignLevels}, "version.isLatestMajor": true, "version.isLatestMinor": true}
  levels = yield Level.find(queryParams)

  # Save original level ID and slug in array for sorting
  campaignOriginalSlugs = []
  for doc in levels
    campaignOriginalSlugs.push
      slug: _.str.slugify(doc.get('name'))
      original: doc.get('original').toString()

  # Sort slugs against original levels from campaign
  campaignOriginalSlugs.sort (a, b) ->
    if campaignLevels.indexOf(a.original) < campaignLevels.indexOf(b.original) then -1 else 1

  # Lookup analytics string IDs for level slugs
  orderedLevelSlugs = []
  orderedLevelSlugs.push item.slug for item in campaignOriginalSlugs
  analyticsStrings = yield AnalyticsString.find({v: {$in: orderedLevelSlugs}})

  levelStringIDSlugMap = {}
  levelStringIDSlugMap[doc._id] = doc.v for doc in analyticsStrings


  # 3. Send back an array of level starts and finishes
  # orderedLevelSlugs - Ordered list of level slugs, used for sorting results
  # levelStringIDSlugMap - Maps level string IDs to level slugs

  campaignLevelIDs = Object.keys(levelStringIDSlugMap)

  analyticsStrings = yield AnalyticsString.find({v: {$in: ['Started Level', 'Saw Victory', 'all']}})

  for doc in analyticsStrings
    startEventID = doc._id if doc.v is 'Started Level'
    finishEventID = doc._id if doc.v is 'Saw Victory'
    filterEventID =  doc._id if doc.v is 'all'

  return res.send([]) unless startEventID? and finishEventID? and filterEventID?

  queryParams = {$and: [
    {$or: [{e: startEventID}, {e: finishEventID}]},
    {f: filterEventID},
    {l: {$in: campaignLevelIDs}}
  ]}
  queryParams["$and"].push {d: {$gte: startDay}} if startDay?
  queryParams["$and"].push {d: {$lt: endDay}} if endDay?
  analyticsPerDays = yield AnalyticsPerDay.find(queryParams)

  levelEventCounts = {}
  for doc in analyticsPerDays
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
  res.send(completions)

module.exports = {
  getActiveClasses,
  getActiveUsers,
  getCampaignCompletionsBySlug
}
