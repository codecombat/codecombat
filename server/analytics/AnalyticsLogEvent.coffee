mongoose = require 'mongoose'
plugins = require '../plugins/plugins'

AnalyticsLogEventSchema = new mongoose.Schema({
  created:
    type: Date
    'default': Date.now
}, {strict:false, minimize: false})
AnalyticsLogEventSchema.index({event: 1, created: -1})

module.exports = AnalyticsLogEvent = mongoose.model('analytics.log.event', AnalyticsLogEventSchema)
