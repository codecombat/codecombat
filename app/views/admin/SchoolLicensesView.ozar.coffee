require('app/styles/admin/admin-school-licenses.sass')
RootView = require 'views/core/RootView'
CocoCollection = require 'collections/CocoCollection'
Prepaid = require 'models/Prepaid'
TrialRequests = require 'collections/TrialRequests'

# TODO: year ranges hard-coded

module.exports = class SchoolLicensesView extends RootView
  id: 'admin-school-licenses-view'
  template: require 'templates/admin/school-licenses'

  initialize: ->
    return super() unless me.isAdmin()
    @startDateRange = new Date()
    @endDateRange = new Date()
    @endDateRange.setUTCFullYear(@endDateRange.getUTCFullYear() + 2)
    @supermodel.addRequestResource({
      url: '/db/prepaid/-/active-schools'
      method: 'GET'
      success: ({prepaidActivityMap, schoolPrepaidsMap}) =>
        @updateSchools(prepaidActivityMap, schoolPrepaidsMap)
    }, 0).load()
    super()

  updateSchools: (prepaidActivityMap, schoolPrepaidsMap) ->
    timeStart = @startDateRange.getTime()
    time2017 = new Date('2017').getTime()
    time2018 = new Date('2018').getTime()
    timeEnd = @endDateRange.getTime()
    rangeMilliseconds = timeEnd - timeStart
    @rangeKeys = [
      {name :'Today', color: 'blue', startScale: 0, width: Math.round((time2017 - timeStart) / rangeMilliseconds * 100)}
      {name: '2017', color: 'red', startScale: Math.round((time2017 - timeStart) / rangeMilliseconds * 100), width: Math.round((time2018 - time2017) / rangeMilliseconds * 100)}
      {name: '2018', color: 'yellow', startScale: Math.round((time2018 - timeStart) / rangeMilliseconds * 100), width: Math.round((timeEnd - time2018) / rangeMilliseconds * 100)}
    ]

    @schools = []
    for school, prepaids of schoolPrepaidsMap
      activity = 0
      schoolMax = 0
      schoolUsed = 0
      collapsedPrepaids = []
      for prepaid in prepaids
        activity += prepaidActivityMap[prepaid._id] ? 0
        startDate = prepaid.startDate
        endDate = prepaid.endDate
        max = parseInt(prepaid.maxRedeemers)
        used = parseInt(prepaid.redeemers?.length ? 0)
        schoolMax += max
        schoolUsed += used
        foundIdenticalDates = false
        for collapsedPrepaid in collapsedPrepaids
          if collapsedPrepaid.startDate.substring(0, 10) is startDate.substring(0, 10) and collapsedPrepaid.endDate.substring(0, 10) is endDate.substring(0, 10)
            collapsedPrepaid.max += parseInt(prepaid.maxRedeemers)
            collapsedPrepaid.used += parseInt(prepaid.redeemers?.length ? 0)
            foundIdenticalDates = true
            break
        unless foundIdenticalDates
          collapsedPrepaids.push({startDate, endDate, max, used})

      for collapsedPrepaid in collapsedPrepaids
        collapsedPrepaid.startScale = (new Date(collapsedPrepaid.startDate).getTime() - @startDateRange.getTime()) / rangeMilliseconds * 100
        if collapsedPrepaid.startScale < 0
          collapsedPrepaid.startScale = 0
          collapsedPrepaid.rangeScale = (new Date(collapsedPrepaid.endDate).getTime() - @startDateRange.getTime()) / rangeMilliseconds * 100
        else
          collapsedPrepaid.rangeScale = (new Date(collapsedPrepaid.endDate).getTime() - new Date(collapsedPrepaid.startDate).getTime()) / rangeMilliseconds * 100
        collapsedPrepaid.rangeScale = 100 - collapsedPrepaid.startScale if collapsedPrepaid.rangeScale + collapsedPrepaid.startScale > 100
      @schools.push {name: school, activity, max: schoolMax, used: schoolUsed, prepaids: collapsedPrepaids, startDate: collapsedPrepaids[0].startDate, endDate: collapsedPrepaids[0].endDate}

    @schools.sort (a, b) ->
      b.activity - a.activity or new Date(a.endDate).getTime() - new Date(b.endDate).getTime() or b.max - a.max or b.used - a.used or b.prepaids.length - a.prepaids.length or b.name.localeCompare(a.name)

    @render()
