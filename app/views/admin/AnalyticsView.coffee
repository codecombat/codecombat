RootView = require 'views/core/RootView'
template = require 'templates/admin/analytics'
utils = require 'core/utils'

module.exports = class AnalyticsView extends RootView
  id: 'admin-analytics-view'
  template: template

  constructor: (options) ->
    super options

    startDay = utils.getUTCDay(-30).replace(/-/g, '')
    endDay = utils.getUTCDay(-30).replace(/-/g, '')

    @supermodel.addRequestResource('active_users', {
      url: '/db/analytics_perday/-/active_users'
      data: {startDay: startDay, endDay: endDay}
      method: 'POST'
      success: (data) =>
        @activeUsers = data
        @activeUsers.sort (a, b) -> b.day.localeCompare(a.day)
        @render?()
    }, 0).load()

    @supermodel.addRequestResource('active_classes', {
      url: '/db/analytics_perday/-/active_classes'
      data: {startDay: startDay, endDay: endDay}
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

  getRenderData: ->
    context = super()
    context.activeClasses = @activeClasses ? []
    context.activeClassGroups = @activeClassGroups ? {}
    context.activeUsers = @activeUsers ? []
    context
