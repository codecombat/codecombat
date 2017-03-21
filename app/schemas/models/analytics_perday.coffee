c = require './../schemas'

AnalyticsPerDaySchema = c.object {
  title: 'Analytics per-day data'
  description: 'Analytics data aggregated into per-day chunks.'
}

_.extend AnalyticsPerDaySchema.properties,
  d: {type: 'string'}   # yyyymmdd day, e.g. '20150123'
  e: {type: 'integer'}  # event (analytics string ID from analytics.strings)
  l: {type: 'integer'}  # level (analytics ID from analytics.strings)
  f: {type: 'integer'}  # filter (analytics ID from analytics.strings)
  fv: {type: 'integer'} # filter value (analytics ID from analytics.strings)
  c: {type: 'integer'}  # count

c.extendBasicProperties AnalyticsPerDaySchema, 'analytics.perday'

module.exports = AnalyticsPerDaySchema
