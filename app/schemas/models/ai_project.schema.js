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
  interactions: c.InteractionArraySchema('The ordered interactions comprising this project'),
  currentInteractionIndex: { type: 'integer', minimum: 0, title: 'Current Interaction Index', description: 'Pointer to interaction representing latest published version of the document. If not at the end, user has reverted to an earlier version of the project (or maybe not published the later interactions yet?).' },
  documents: {
    type: 'object',
    title: 'Documents',
    description: 'Document names -> _ids for the documents in the current version of this project',
    additionalProperties: {
      type: c.objectId({links: [{rel: 'db', href: '/db/ai_document/{($)}'}]})
    }
  }
})

AIProjectSchema.definitions = {}
c.extendBasicProperties(AIProjectSchema, 'ai_project')
c.extendSearchableProperties(AIProjectSchema)
c.extendPermissionsProperties(AIProjectSchema, 'ai_project')

module.exports = AIProjectSchema
