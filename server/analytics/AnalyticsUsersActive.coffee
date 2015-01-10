mongoose = require 'mongoose'
plugins = require '../plugins/plugins'

AnalyticsUsersActiveSchema = new mongoose.Schema({
  created:
    type: Date
    'default': Date.now
}, {strict: false})

module.exports = AnalyticsUsersActive = mongoose.model('analytics.users.active', AnalyticsUsersActiveSchema)
