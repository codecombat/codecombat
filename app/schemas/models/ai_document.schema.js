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
  source: { type: 'string', description: 'The contents of the document' }
})

AIDocumentSchema.definitions = {}
c.extendBasicProperties(AIDocumentSchema, 'ai_document')
// c.extendSearchableProperties(AIDocumentSchema)
// c.extendPermissionsProperties(AIDocumentSchema, 'ai_document')

module.exports = AIDocumentSchema
