mongoose = require 'mongoose'
plugins = require '../plugins/plugins'

AnalyticsLogEventSchema = new mongoose.Schema({
  u: mongoose.Schema.Types.ObjectId
  e: Number  # event analytics.string ID
  p: mongoose.Schema.Types.Mixed

  # TODO: Remove these legacy properties after we stop querying for them (probably 30 days, ~2/16/15)
  user: mongoose.Schema.Types.ObjectId
  event: String
  properties: mongoose.Schema.Types.Mixed
}, {strict: false})
AnalyticsLogEventSchema.index({event: 1, _id: 1})

module.exports = AnalyticsLogEvent = mongoose.model('analytics.log.event', AnalyticsLogEventSchema)
