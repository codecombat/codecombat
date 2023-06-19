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
  description: {
    title: 'Description',
    description: 'A short explanation of what this project is about',
    type: 'string',
    maxLength: 2000,
    format: 'markdown'
  },
  owner: c.objectId(),
  scenario: c.objectId(),
  spokenLanguage: c.shortString(),
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

AIProjectSchema.definitions = {}
c.extendBasicProperties(AIProjectSchema, 'ai_project')
// c.extendSearchableProperties(AIProjectSchema)
// c.extendPermissionsProperties(AIProjectSchema, 'ai_project')

module.exports = AIProjectSchema
