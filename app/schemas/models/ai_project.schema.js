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
  scenario: c.objectId(),
  created: c.date({ title: 'Created', readOnly: true }),
  visibility: {
    type: 'string',
    enum: ['private', 'public', 'published'],
    title: 'Visibility',
    description: 'Whether this project is private, public but unlisted, or public and published'
  },
  actionQueue: {
    type: 'array',
    description: 'Actions left to perform in this project'
  }
})

c.extendBasicProperties(AIProjectSchema, 'ai_project')
// c.extendPermissionsProperties(AIProjectSchema, 'ai_project')

module.exports = AIProjectSchema
