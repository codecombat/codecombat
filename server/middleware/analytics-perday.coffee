wrap = require 'co-express'
AnalyticsString = require './../models/AnalyticsString'
AnalyticsPerDay = require './../models/AnalyticsPerDay'

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

  
module.exports = {
  getActiveClasses,
  getActiveUsers
}
