RootView = require 'views/core/RootView'
template = require 'templates/admin/analytics'
utils = require 'core/utils'

module.exports = class AnalyticsView extends RootView
  id: 'admin-analytics-view'
  template: template

  constructor: (options) ->
    super options

    @supermodel.addRequestResource('active_classes', {
      url: '/db/analytics_perday/-/active_classes'
      method: 'POST'
      success: (data) =>
        @activeClassGroups = {}
        dayEventsMap = {}
        for activeClass in data
          dayEventsMap[activeClass.day] ?= {}
          dayEventsMap[activeClass.day]['Total'] = 0
          for event, val of activeClass.classes
            @activeClassGroups[event] = true
            dayEventsMap[activeClass.day][event] = val
            dayEventsMap[activeClass.day]['Total'] += val
        @activeClassGroups = Object.keys(@activeClassGroups)
        @activeClassGroups.push 'Total'
        for day of dayEventsMap
          for event in @activeClassGroups
            dayEventsMap[day][event] ?= 0
        @activeClasses = []
        for day of dayEventsMap
          data = day: day, groups: []
          for group in @activeClassGroups
            data.groups.push(dayEventsMap[day][group] ? 0)
          @activeClasses.push data
        @activeClasses.sort (a, b) -> b.day.localeCompare(a.day)
        @render?()
    }, 0).load()

    @supermodel.addRequestResource('active_users', {
      url: '/db/analytics_perday/-/active_users'
      method: 'POST'
      success: (data) =>
        @activeUsers = data
        @activeUsers.sort (a, b) -> b.day.localeCompare(a.day)
        @render?()
    }, 0).load()

    @supermodel.addRequestResource('recurring_revenue', {
      url: '/db/analytics_perday/-/recurring_revenue'
      method: 'POST'
      success: (data) =>
        @revenueGroups = {}
        dayGroupCountMap = {}
        for dailyRevenue in data
          dayGroupCountMap[dailyRevenue.day] ?= {}
          dayGroupCountMap[dailyRevenue.day]['Daily'] = 0
          for group, val of dailyRevenue.groups
            @revenueGroups[group] = true
            dayGroupCountMap[dailyRevenue.day][group] = val
            dayGroupCountMap[dailyRevenue.day]['Daily'] += val
        @revenueGroups = Object.keys(@revenueGroups)
        @revenueGroups.push 'Daily'
        @revenueGroups.push 'Monthly'
        for day of dayGroupCountMap
          for group in @revenueGroups
            dayGroupCountMap[day][group] ?= 0
        @revenue = []
        for day of dayGroupCountMap
          data = day: day, groups: []
          for group in @revenueGroups
            data.groups.push(dayGroupCountMap[day][group] ? 0)
          @revenue.push data
        @revenue.sort (a, b) -> b.day.localeCompare(a.day)
        monthlyValues = []

        return unless @revenue.length > 0

        for i in [@revenue.length-1..0]
          dailyTotal = @revenue[i].groups[@revenue[i].groups.length - 2]
          monthlyValues.push(dailyTotal)
          monthlyValues.shift() if monthlyValues.length > 30
          if monthlyValues.length is 30
            monthlyIndex = @revenue[i].groups.length - 1
            @revenue[i].groups[monthlyIndex] = _.reduce(monthlyValues, (s, num) -> s + num)
        @render?()
    }, 0).load()

  getRenderData: ->
    context = super()
    context.activeClasses = @activeClasses ? []
    context.activeClassGroups = @activeClassGroups ? {}
    context.activeUsers = @activeUsers ? []
    context.revenue = @revenue ? []
    context.revenueGroups = @revenueGroups ? {}
    context
