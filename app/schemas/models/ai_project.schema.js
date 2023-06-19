const c = require('./../schemas')
const _ = require('lodash')

const AIProjectSchema = c.object({
  title: 'AI Project',
  description: 'A generative AI project',
  required: ['owner'], // TODO: more required properties
  default: { interactions: [] }
})

c.extendNamedProperties(AIProjectSchema) // TODO: are we doing unique names? or non-unique? slug?

_.extend(AIProjectSchema.properties, {
  user: c.objectId(),
  scenario: c.objectId(),
  created: c.date({ title: 'Created', readOnly: true }),
  actionQueue: {
    type: 'array',
    description: 'Actions left to perform in this project'
  }
})

AIProjectSchema.definitions = {}
c.extendBasicProperties(AIProjectSchema, 'ai_project')
// c.extendSearchableProperties(AIProjectSchema)
// c.extendPermissionsProperties(AIProjectSchema, 'ai_project')

module.exports = AIProjectSchema
