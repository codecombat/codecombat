// WARNING: This file is auto-generated from within AI HackStack. Do not edit directly.
// Instead, edit the corresponding Zod schema in the HackStack repo and run `npm run build` or `npm run build:schemas
//
// Last updated: 2023-09-08T05:55:38.100Z

const _ = require('lodash')
const c = require('./../schemas')

const AIProjectSchema = c.object({
  title: 'AI Project',
  description: 'A generative AI project'
})

_.extend(AIProjectSchema.properties, {
  name: { title: 'Name', type: 'string', maxLength: 100 },
  description: {
    title: 'Description',
    type: 'string',
    description: 'A short explanation of what this project is about',
    maxLength: 2000
  },
  visibility: {
    title: 'Visibility',
    type: 'string',
    description: 'Whether this project is private, public but unlisted, or public and published',
    enum: ['private', 'public', 'published']
  },
  user: {
    title: 'User',
    type: ['object', 'string'],
    description: 'The user ID of the project owner',
    links: [{ rel: 'db', href: '/db/user/{($)}' }]
  },
  scenario: {
    title: 'Scenario',
    type: ['object', 'string'],
    description: 'The scenario ID of the project',
    links: [{ rel: 'db', href: '/db/ai_scenario/{($)}' }]
  },
  actionQueue: {
    title: 'Action Queue',
    type: 'array',
    description: 'Actions left to perform in this project, represented as AI Chat Messages',
    items: { type: ['object', 'string'], format: 'chat-message-link' }
  }
})

AIProjectSchema.required = ['visibility', 'user', 'scenario', 'actionQueue']

c.extendBasicProperties(AIProjectSchema, 'ai_project')
c.extendPermissionsProperties(AIProjectSchema, 'ai_project')

module.exports = AIProjectSchema
