mongoose = require 'mongoose'

AnalyticsPerDaySchema = new mongoose.Schema({
  d: {type: String}  # yyyymmdd day, e.g. '20150123'
  e: {type: Number}  # event (analytics string ID from analytics.strings)
  l: {type: Number}  # level (analytics string ID from analytics.strings)
  f: {type: Number}  # filter (analytics string ID from analytics.strings)
  fv: {type: Number} # filter value (analytics string ID from analytics.strings)
  c: {type: Number}  # count
}, {strict: false})

# TODO: Why can't we query against a collection with caps, like 'analytics.perDay'?
module.exports = AnalyticsPerDay = mongoose.model('analytics.perday', AnalyticsPerDaySchema)
