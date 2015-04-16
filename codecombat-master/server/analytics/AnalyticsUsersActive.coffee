mongoose = require 'mongoose'
plugins = require '../plugins/plugins'

AnalyticsUsersActiveSchema = new mongoose.Schema({
  created:
    type: Date
    'default': Date.now
}, {strict: false})

AnalyticsUsersActiveSchema.index({created: 1})
AnalyticsUsersActiveSchema.index({creator: 1})

module.exports = AnalyticsUsersActive = mongoose.model('analytics.users.active', AnalyticsUsersActiveSchema)
