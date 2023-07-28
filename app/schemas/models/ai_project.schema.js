const c = require('./../schemas')
const _ = require('lodash')

const AIProjectSchema = c.object({
  title: 'AI Project',
  description: 'A generative AI project',
})

_.extend(AIProjectSchema.properties, {
  name: {
    type: 'string',
    description: 'The name of the project'
  },
  user: c.objectId({
    links: [{ rel: 'db', href: '/db/user/{($)}' }],
    title: 'User ID',
    description: 'The user ID of the project owner'
  }),
  scenario: c.objectId({
    links: [{ rel: 'db', href: '/db/ai_scenario/{($)}' }],
    title: 'SCENARIO ID',
    description: 'The scenario ID of the project'
  }),
  created: c.date({ title: 'Created', readOnly: true }),
  visibility: {
    type: 'string',
    enum: ['private', 'public', 'published'],
    title: 'Visibility',
    description: 'Whether this project is private, public but unlisted, or public and published'
  },
  actionQueue: c.array({
    title: 'Action Queue',
    description: 'Actions left to perform in this project'
  }, c.objectId({format: 'chat-message-link'})),
})

c.extendBasicProperties(AIProjectSchema, 'ai_project')
c.extendPermissionsProperties(AIProjectSchema, 'ai_project')

module.exports = AIProjectSchema
