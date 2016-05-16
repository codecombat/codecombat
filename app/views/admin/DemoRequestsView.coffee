RootView = require 'views/core/RootView'
template = require 'templates/admin/demo-requests'
CocoCollection = require 'collections/CocoCollection'
TrialRequest = require 'models/TrialRequest'

module.exports = class DemoRequestsView extends RootView
  id: 'admin-demo-requests-view'
  template: template

  constructor: (options) ->
    super options
    return unless me.isAdmin()
    @trialRequests = new CocoCollection([], { url: '/db/trial.request?conditions[sort]="-created"&conditions[limit]=5000', model: TrialRequest })
    @supermodel.loadCollection(@trialRequests, 'trial-requests', {cache: false})
    @dayCounts = []

  onLoaded: ->
    return super() unless me.isAdmin()
    dayCountMap = {}
    for trialRequest in @trialRequests.models
      day = trialRequest.get('created').substring(0, 10)
      dayCountMap[day] ?= 0
      dayCountMap[day]++
    @dayCounts = []
    for day, count of dayCountMap
      @dayCounts.push(day: day, count: count)
    @dayCounts.sort((a, b) -> b.day.localeCompare(a.day))
    sevenCounts = []
    for i in [@dayCounts.length - 1..0]
      dayCount = @dayCounts[i]
      sevenCounts.push(dayCount.count)
      while sevenCounts.length > 7
        sevenCounts.shift()
      if sevenCounts.length is 7
        dayCount.sevenAverage = Math.round(sevenCounts.reduce(((a, b) -> a + b), 0) / 7)
    super()
