import schema from './../schemas';

const UserStatsSchema = schema.object({}, {
  userId: schema.objectId({ links: [ { rel: 'extra', href: '/db/user/{($)}' } ] }),
  stats: schema.object(
    {
      title: 'User stats',
      additionalProperties: true
    }
  ),
  lastUpdatedAt: schema.stringDate()
})

schema.extendBasicProperties(UserStatsSchema, 'user.stat')

export default UserStatsSchema;
