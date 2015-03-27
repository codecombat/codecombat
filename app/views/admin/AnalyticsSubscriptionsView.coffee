RootView = require 'views/core/RootView'
template = require 'templates/admin/analytics-subscriptions'
RealTimeCollection = require 'collections/RealTimeCollection'

require 'vendor/d3'

module.exports = class AnalyticsSubscriptionsView extends RootView
  id: 'admin-analytics-subscriptions-view'
  template: template

  constructor: (options) ->
    super options
    if me.isAdmin()
      @refreshData()
      _.delay (=> @refreshData()), 30 * 60 * 1000

  getRenderData: ->
    context = super()
    context.subs = @subs ? []
    context.total = @total ? 0
    context.cancelled = @cancelled ? 0
    context

  refreshData: ->
    return unless me.isAdmin()
    @subs = []
    @total = 0
    @cancelled = 0
    onSuccess = (subs) =>
      subDayMap = {}
      for sub in subs
        startDay = sub.start.substring(0, 10)
        subDayMap[startDay] ?= {}
        subDayMap[startDay]['start'] ?= 0
        subDayMap[startDay]['start']++
        if cancelDay = sub?.cancel?.substring(0, 10)
          subDayMap[cancelDay] ?= {}
          subDayMap[cancelDay]['cancel'] ?= 0
          subDayMap[cancelDay]['cancel']++
      for day of subDayMap
        @subs.push
          day: day
          started: subDayMap[day]['start']
          cancelled: subDayMap[day]['cancel'] or 0
      @subs.sort (a, b) -> -a.day.localeCompare(b.day)

      for i in [@subs.length - 1..0]
        @total += @subs[i].started
        @cancelled += @subs[i].cancelled
        @subs[i].total = @total
      @render()
    @supermodel.addRequestResource('subscriptions', {
      url: '/db/subscription/-/subscriptions'
      method: 'GET'
      success: onSuccess
    }, 0).load()
