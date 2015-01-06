mongoose = require 'mongoose'
plugins = require '../plugins/plugins'

AnalyticsLogEventSchema = new mongoose.Schema({
  created:
    type: Date
    'default': Date.now
}, {strict: false})
AnalyticsLogEventSchema.index event: 1
AnalyticsLogEventSchema.index created: -1

module.exports = AnalyticsLogEvent = mongoose.model('analytics.log.event', AnalyticsLogEventSchema)
