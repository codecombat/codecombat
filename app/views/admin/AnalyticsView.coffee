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
    request = @supermodel.addRequestResource 'active_users', {
      url: '/db/analytics_perday/-/active_users'
      data: {startDay: startDay, endDay: endDay}
      method: 'POST'
      success: (data) =>
        @activeUsers = data
        @activeUsers.sort (a, b) -> b.day.localeCompare(a.day)
        @render?()
    }, 0
    request.load()

  getRenderData: ->
    context = super()
    context.activeUsers = @activeUsers ? []
    context
