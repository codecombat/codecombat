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


module.exports = {
  getActiveClasses
}
