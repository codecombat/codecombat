const c = require('../schemas')

const LowUsageUserSchema = c.object({
  title: 'Low Usage Users',
  description: 'Users with low usage based on defined criterias',
  properties: {
    userId: c.objectId({}),
    criterias: c.array(c.shortString()),
    updatedAt: c.date(),
    actions: c.array(
      c.object({
        name: c.shortString(),
        date: c.date(),
        userId: c.objectId()
      })
    ),
    logs: c.array(
      c.object({
        criterias: c.array(c.shortString()),
        date: c.date()
      })
    )
  }
})

module.exports = LowUsageUserSchema
