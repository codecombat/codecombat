CocoModel = require './CocoModel'

module.exports = class AnalyticsLogEvent extends CocoModel
  @className: 'AnalyticsLogEvent'
  @schema: require 'schemas/models/analytics_log_event'
  urlRoot: '/db/analytics.log.event'
