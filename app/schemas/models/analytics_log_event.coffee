c = require './../schemas'

AnalyticsLogEventSchema = c.object {
  title: 'Analytics Log Event'
  description: 'Analytics event logs.'
}

_.extend AnalyticsLogEventSchema.properties,
  u: c.objectId(links: [{rel: 'extra', href: '/db/user/{($)}'}])
  e: {type: 'integer'}
  p: {type: 'object'}

  # TODO: Remove these legacy properties after we stop querying for them (probably 30 days, ~2/16/15)
  user: c.objectId(links: [{rel: 'extra', href: '/db/user/{($)}'}])
  event: {type: 'string'}
  properties: {type: 'object'}

c.extendBasicProperties AnalyticsLogEventSchema, 'analytics.log.event'

module.exports = AnalyticsLogEventSchema
