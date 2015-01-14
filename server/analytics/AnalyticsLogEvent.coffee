mongoose = require 'mongoose'
plugins = require '../plugins/plugins'

AnalyticsLogEventSchema = new mongoose.Schema({}, {strict: false})
AnalyticsLogEventSchema.index({event: 1, _id: 1})

module.exports = AnalyticsLogEvent = mongoose.model('analytics.log.event', AnalyticsLogEventSchema)
