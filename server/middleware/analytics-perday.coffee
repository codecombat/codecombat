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

campaignCompletionsCache = {}
campaignCompletionsCachedSince = new Date()

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
  module.exports.campaignCompletionsCache ?= {}
  module.exports.campaignCompletionsCachedSince ?= new Date()
  if (new Date()) - module.exports.campaignCompletionsCachedSince > 86400 * 1000
    module.exports.campaignCompletionsCache = {}
    module.exports.campaignCompletionsCachedSince = new Date()
  cacheKey = campaignSlug
  cacheKey += 's' + startDay if startDay?
  cacheKey += 'e' + endDay if endDay?
  return res.send(completions) if completions = module.exports.campaignCompletionsCache[cacheKey]

  
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

  module.exports.campaignCompletionsCache[cacheKey] = completions
  res.send(completions)


getLevelCompletionsBySlug = wrap (req, res) ->
  # Returns an array of per-day starts and finishes for given level
  # Parameters:
  # slug - level slug
  # startDay - Inclusive, optional, YYYYMMDD e.g. '20141214'
  # endDay - Exclusive, optional, YYYYMMDD e.g. '20141216'

  # TODO: Code is similar to getCampaignCompletionsBySlug

  levelSlug = req.body.slug
  startDay = req.body.startDay
  endDay = req.body.endDay

  return res.send([]) unless levelSlug?

  # Cache results in app server memory for 1 day
  module.exports.levelCompletionsCache ?= {}
  module.exports.levelCompletionsCachedSince ?= new Date()
  if (new Date()) - module.exports.levelCompletionsCachedSince > 86400 * 1000
    module.exports.levelCompletionsCache = {}
    module.exports.levelCompletionsCachedSince = new Date()
  cacheKey = levelSlug
  cacheKey += 's' + startDay if startDay?
  cacheKey += 'e' + endDay if endDay?
  return res.send(levelCompletions) if levelCompletions = module.exports.levelCompletionsCache[cacheKey]

  documents = yield AnalyticsString.find({v: {$in: ['Started Level', 'Saw Victory', 'all', levelSlug]}})

  for doc in documents
    startEventID = doc._id if doc.v is 'Started Level'
    finishEventID = doc._id if doc.v is 'Saw Victory'
    filterEventID =  doc._id if doc.v is 'all'
    levelID = doc._id if doc.v is levelSlug
  return res.send([]) unless startEventID? and finishEventID? and filterEventID? and levelID?

  queryParams = {$and: [{$or: [{e: startEventID}, {e: finishEventID}]},{f: filterEventID},{l: levelID}]}
  queryParams["$and"].push {d: {$gte: startDay}} if startDay?
  queryParams["$and"].push {d: {$lt: endDay}} if endDay?
  
  documents = yield AnalyticsPerDay.find(queryParams)

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

  module.exports.levelCompletionsCache[cacheKey] = completions
  res.send(completions)


getLevelDropsBySlugs = wrap (req, res) ->
  # Send back an array of level/drops
  # Drops - Number of unique users for which this was the last level they played
  # Parameters:
  # slugs - level slugs
  # startDay - Inclusive, optional, YYYYMMDD e.g. '20141214'
  # endDay - Exclusive, optional, YYYYMMDD e.g. '20141216'

  levelSlugs = req.body.slugs
  startDay = req.body.startDay
  endDay = req.body.endDay

  return res.send([]) unless levelSlugs?

  # Cache results in app server memory for 1 day
  module.exports.levelDropsCache ?= {}
  module.exports.levelDropsCachedSince ?= new Date()
  if (new Date()) - module.exports.levelDropsCachedSince > 86400 * 1000
    module.exports.levelDropsCache = {}
    module.exports.levelDropsCachedSince = new Date()
  cacheKey = levelSlugs.join ''
  cacheKey += 's' + startDay if startDay?
  cacheKey += 'e' + endDay if endDay?
  return res.send(drops) if drops = module.exports.levelDropsCache[cacheKey]

  documents = yield AnalyticsString.find({v: {$in: ['User Dropped', 'all'].concat(levelSlugs)}})

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
  documents = yield AnalyticsPerDay.find(queryParams)

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

  module.exports.levelDropsCache[cacheKey] = drops
  res.send(drops)


getLevelHelpsBySlugs = wrap (req, res) ->
  # Send back an array of per-day level help buttons clicked and videos started
  # Parameters:
  # slugs - level slugs
  # startDay - Inclusive, optional, YYYYMMDD e.g. '20141214'
  # endDay - Exclusive, optional, YYYYMMDD e.g. '20141216'

  levelSlugs = req.body.slugs
  startDay = req.body.startDay
  endDay = req.body.endDay

  # log.warn "level_helps levelSlugs='#{levelSlugs}' startDay=#{startDay} endDay=#{endDay}"

  return res.send([]) unless levelSlugs?

  # Cache results in app server memory for 1 day
  module.exports.levelHelpsCache ?= {}
  module.exports.levelHelpsCachedSince ?= new Date()
  if (new Date()) - module.exports.levelHelpsCachedSince > 86400 * 1000
    module.exports.levelHelpsCache = {}
    module.exports.levelHelpsCachedSince = new Date()
  cacheKey = levelSlugs.join ''
  cacheKey += 's' + startDay if startDay?
  cacheKey += 'e' + endDay if endDay?
  return res.send(helps) if helps = module.exports.levelHelpsCache[cacheKey]

  findQueryParams = {v: {$in: ['Problem alert help clicked', 'Spell palette help clicked', 'Start help video', 'all'].concat(levelSlugs)}}
  documents = yield AnalyticsString.find(findQueryParams)

  levelStringIDSlugMap = {}
  for doc in documents
    alertHelpEventID = doc._id if doc.v is 'Problem alert help clicked'
    palettteHelpEventID = doc._id if doc.v is 'Spell palette help clicked'
    videoHelpEventID = doc._id if doc.v is 'Start help video'
    filterEventID =  doc._id if doc.v is 'all'
    levelStringIDSlugMap[doc._id] = doc.v if doc.v in levelSlugs

  return res.send([]) unless alertHelpEventID? and palettteHelpEventID? and videoHelpEventID? and filterEventID?

  queryParams = {$and: [
    {e: {$in: [alertHelpEventID, palettteHelpEventID, videoHelpEventID]}},
    {f: filterEventID},
    {l: {$in: Object.keys(levelStringIDSlugMap)}}
  ]}
  queryParams["$and"].push {d: {$gte: startDay}} if startDay?
  queryParams["$and"].push {d: {$lt: endDay}} if endDay?
  documents = yield AnalyticsPerDay.find(queryParams)

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

  module.exports.levelHelpsCache[cacheKey] = helps
  res.send(helps)


getLevelSubscriptionsBySlugs = wrap (req, res) ->
  # Send back an array of level subscriptions shown and purchased counts
  # Parameters:
  # slugs - level slugs
  # startDay - Inclusive, optional, YYYYMMDD e.g. '20141214'
  # endDay - Exclusive, optional, YYYYMMDD e.g. '20141216'

  levelSlugs = req.query.slugs or req.body.slugs
  startDay = req.query.startDay or req.body.startDay
  endDay = req.query.endDay or req.body.endDay

  # log.warn "level_subscriptions levelSlugs='#{levelSlugs}' startDay=#{startDay} endDay=#{endDay}"

  return res.send([]) unless levelSlugs?

  # Cache results in app server memory for 1 day
  module.exports.levelSubscriptionsCache ?= {}
  module.exports.levelSubscriptionsCachedSince ?= new Date()
  if (new Date()) - module.exports.levelSubscriptionsCachedSince > 86400 * 1000
    module.exports.levelSubscriptionsCache = {}
    module.exports.levelSubscriptionsCachedSince = new Date()
  cacheKey = levelSlugs.join ''
  cacheKey += 's' + startDay if startDay?
  cacheKey += 'e' + endDay if endDay?
  return res.send(subscriptions) if subscriptions = module.exports.levelSubscriptionsCache[cacheKey]

  findQueryParams = {v: {$in: ['Show subscription modal', 'Finished subscription purchase', 'all'].concat(levelSlugs)}}
  documents = yield AnalyticsString.find(findQueryParams)

  levelStringIDSlugMap = {}
  for doc in documents
    showSubEventID = doc._id if doc.v is 'Show subscription modal'
    finishSubEventID = doc._id if doc.v is 'Finished subscription purchase'
    filterEventID =  doc._id if doc.v is 'all'
    levelStringIDSlugMap[doc._id] = doc.v if doc.v in levelSlugs

  res.send([]) unless showSubEventID? and finishSubEventID? and filterEventID?

  queryParams = {$and: [
    {e: {$in: [showSubEventID, finishSubEventID]}},
    {f: filterEventID},
    {l: {$in: Object.keys(levelStringIDSlugMap)}}
  ]}
  queryParams["$and"].push {d: {$gte: startDay}} if startDay?
  queryParams["$and"].push {d: {$lt: endDay}} if endDay?
  documents = yield AnalyticsPerDay.find(queryParams)

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

  module.exports.levelSubscriptionsCache[cacheKey] = subscriptions
  res.send(subscriptions)


getRecurringRevenue = wrap (req, res) ->
  events = [
    'DRR gems',
    'DRR school sales',
    'DRR yearly subs',
    'DRR monthly subs',
    'DRR paypal',
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
  recurringRevenue = []
  for key, val of dayCountsMap
    recurringRevenue.push day: key, groups: dayCountsMap[key] ? {}
  res.send(recurringRevenue)  

  
module.exports = {
  getActiveClasses,
  getActiveUsers,
  getCampaignCompletionsBySlug,
  getLevelCompletionsBySlug,
  getLevelDropsBySlugs,
  getLevelHelpsBySlugs,
  getLevelSubscriptionsBySlugs,
  getRecurringRevenue
}
