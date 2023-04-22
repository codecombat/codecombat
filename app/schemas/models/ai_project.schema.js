const c = require('./../schemas')
const _ = require('lodash')

const AIProjectSchema = c.object({
  title: 'AI Project',
  description: 'A generative AI project',
  required: ['owner'], // TODO: more required properties
  default: {}
})

c.extendNamedProperties(AIProjectSchema)

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
  content: {
    type: 'array',
    title: 'Content',
    description: 'The prompts and other content making up this project',
    items: {
      type: 'object',
      title: 'Content Item',
      description: 'TODO: some prompt or something',
      additionalProperties: true
    }
    // TODO: think of how this should go. Maybe it's a reference to an AIPrompt or ChatMessage or an AILesson or some other interstitial content type? Is it linear (array)?
  }
})

AIProjectSchema.definitions = {}
c.extendBasicProperties(AIProjectSchema, 'ai_project')
c.extendSearchableProperties(AIProjectSchema)
c.extendPermissionsProperties(AIProjectSchema, 'ai_project')

module.exports = AIProjectSchema

