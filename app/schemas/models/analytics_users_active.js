// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
const c = require('./../schemas')

const AnalyticsUsersActiveSchema = c.object({
  title: 'Analytics Users Active',
  description: 'Active users data.'
})

_.extend(AnalyticsUsersActiveSchema.properties, {
  creator: c.objectId({ links: [{ rel: 'extra', href: '/db/user/{($)}' }] }),
  created: c.date({ title: 'Created', readOnly: true }),

  event: { type: 'string' }
})

c.extendBasicProperties(AnalyticsUsersActiveSchema, 'analytics.users.active')

module.exports = AnalyticsUsersActiveSchema
