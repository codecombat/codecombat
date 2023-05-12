const c = require('./../schemas')
const _ = require('lodash')

const AIInteractionSchema = c.object({
  title: 'AI Interaction',
  description: 'A generative AI interaction',
  required: ['messages'], // TODO: more required properties
  default: {}
})

_.extend(AIInteractionSchema.properties, {
  user: c.objectId(),
  scenario: c.objectId(),
  project: c.objectId(), // Scenario link, project link, both, neither?
  spokenLanguage: c.shortString(),
  created: c.date({ title: 'Created', readOnly: true }),
  startDate: c.date({ title: 'Start Date', description: 'The time the message started being sent' }),
  endDate: c.date({ title: 'End Date', description: 'The time the message finished being sent' }),
  messages: c.array({
    title: 'Messages',
    items: c.object({}, {
      content: { type: 'string' },
      role: { type: 'string', enum: ['system', 'user', 'assistant'] }
    })
  }),
  options: {
    type: 'object',
    description: 'Options for the AI interaction',
    properties: {
      temperature: { type: 'number' }
    },
    additionalProperties: true
  }
})

AIInteractionSchema.definitions = {}
c.extendBasicProperties(AIInteractionSchema, 'ai_interaction')
// c.extendSearchableProperties(AIInteractionSchema)
// c.extendPermissionsProperties(AIInteractionSchema, 'ai_interaction')

module.exports = AIInteractionSchema
