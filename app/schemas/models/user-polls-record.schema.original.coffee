c = require './../schemas'

UserPollsRecordSchema = c.object {title: 'UserPollsRecord'}

_.extend UserPollsRecordSchema.properties,
  user: c.stringID {links: [{rel: 'extra', href: '/db/user/{($)}'}]}
  polls:  # Poll ID strings -> answer key strings
    type: 'object'
    additionalProperties: c.shortString {pattern: '^[a-z0-9-]+$'}
  rewards:  # Poll ID strings -> reward objects, for calculating gems
    type: 'object'
    additionalProperties: c.object {},
      random: {type: 'number', minimum: 0, maximum: 1}
      level: {type: 'integer', minimum: 1}
  level: {type: 'integer', minimum: 1, description: 'The player level when last saved.'}
  changed: c.date title: 'Changed', readOnly: true  # Controls when next poll is available

c.extendBasicProperties UserPollsRecordSchema, 'user-polls-record'

module.exports = UserPollsRecordSchema
