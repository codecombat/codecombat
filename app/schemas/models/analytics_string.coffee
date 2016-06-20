c = require './../schemas'

AnalyticsStringSchema = c.object {
  title: 'Analytics String'
  description: 'Maps strings to number IDs for improved performance.'
}

_.extend AnalyticsStringSchema.properties,
  v: {type: 'string'} # value

c.extendBasicProperties AnalyticsStringSchema, 'analytics.string'

module.exports = AnalyticsStringSchema
