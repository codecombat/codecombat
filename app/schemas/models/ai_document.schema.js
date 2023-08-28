const c = require('./../schemas')
const _ = require('lodash')

const AIDocumentSchema = c.object({
  title: 'AI Document',
  description: 'A generative AI document',
})

_.extend(AIDocumentSchema.properties, {
  type: { type: 'string', description: 'The file type (html, py, jpg, etc.)' },
  source: { type: 'string', description: 'The contents of the document', format: 'document-by-type' }
})

c.extendBasicProperties(AIDocumentSchema, 'ai_document')
c.extendSearchableProperties(AIDocumentSchema)
c.extendPatchableProperties(AIDocumentSchema)
c.extendVersionedProperties(AIDocumentSchema, 'ai_document')
// c.extendPermissionsProperties(AIDocumentSchema, 'ai_scenario')
// c.extendTranslationCoverageProperties(AIDocumentSchema)

module.exports = AIDocumentSchema
