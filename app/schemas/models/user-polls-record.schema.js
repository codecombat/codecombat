const c = require('./../schemas')

const UserPollsRecordSchema = c.object({ title: 'UserPollsRecord' })

_.extend(UserPollsRecordSchema.properties, {
  user: c.stringID({ links: [{ rel: 'extra', href: '/db/user/{($)}' }] }),
  polls: { // Poll ID strings -> answer key strings
    type: 'object',
    additionalProperties: c.shortString({ pattern: '^[a-z0-9-]+$' })
  },
  rewards: { // Poll ID strings -> reward objects, for calculating gems
    type: 'object',
    additionalProperties: c.object({}, {
      random: { type: 'number', minimum: 0, maximum: 1 },
      // `level` here means the player's Rank (XP level) when the reward was granted, not a playable level.
      // Persisted data key — keep the legacy `level` name (GD-849).
      level: { type: 'integer', minimum: 1 }
    })
  },
  // `level` here means the player's Rank (XP level), not a playable level. Persisted data key written by
  // the server (user_polls_record_handler) — keep the legacy `level` name (GD-849).
  level: { type: 'integer', minimum: 1, description: 'The player Rank (XP level) when last saved.' },
  changed: c.date({ title: 'Changed', readOnly: true })
}
) // Controls when next poll is available

c.extendBasicProperties(UserPollsRecordSchema, 'user-polls-record')

module.exports = UserPollsRecordSchema
