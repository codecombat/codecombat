const c = require('./../schemas')
const _ = require('lodash')

const AIDocumentSchema = c.object({
  title: 'AI Document',
  description: 'A generative AI document',
  required: ['type'], // TODO: required properties (name? content? owner?)
  default: {}
})

_.extend(AIDocumentSchema.properties, {
  type: { type: 'string', description: 'The file type (html, py, jpg, etc.)' },
  owner: c.objectId(),
  scenario: c.objectId(),
  project: c.objectId(), // Scenario link, project link, both, neither?
  created: c.date({ title: 'Created', readOnly: true }),
  name: { type: 'string' },
  content: c.object({}, {
    text: { type: 'string', description: 'Text contents of this document' },
    url: { type: 'string', format: 'file', description: 'File link to binary contents of this document' }
  })
})

AIDocumentSchema.definitions = {}
c.extendBasicProperties(AIDocumentSchema, 'ai_document')
// c.extendSearchableProperties(AIDocumentSchema)
// c.extendPermissionsProperties(AIDocumentSchema, 'ai_document')

module.exports = AIDocumentSchema
