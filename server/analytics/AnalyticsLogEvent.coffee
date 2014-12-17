mongoose = require 'mongoose'
plugins = require '../plugins/plugins'

AnalyticsLogEventSchema = new mongoose.Schema({
  created:
    type: Date
    'default': Date.now
}, {strict: false})

module.exports = AnalyticsLogEvent = mongoose.model('analytics.log.event', AnalyticsLogEventSchema)
