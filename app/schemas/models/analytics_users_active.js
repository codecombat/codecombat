c = require './../schemas'

AnalyticsUsersActiveSchema = c.object {
  title: 'Analytics Users Active'
  description: 'Active users data.'
}

_.extend AnalyticsUsersActiveSchema.properties,
  creator: c.objectId(links: [{rel: 'extra', href: '/db/user/{($)}'}])
  created: c.date({title: 'Created', readOnly: true})

  event: {type: 'string'}

c.extendBasicProperties AnalyticsUsersActiveSchema, 'analytics.users.active'

module.exports = AnalyticsUsersActiveSchema
