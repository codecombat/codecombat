const c = require('./../schemas')
const _ = require('lodash')

const AIDocumentSchema = c.object({
  title: 'AI Document',
  description: 'A generative AI document',
})

_.extend(AIDocumentSchema.properties, {
  type: { type: 'string', description: 'The file type (html, py, jpg, etc.)' },
  source: { type: 'string', description: 'The contents of the document' }
})

c.extendBasicProperties(AIDocumentSchema, 'ai_document')
c.extendSearchableProperties(AIDocumentSchema)
c.extendPatchableProperties(AIDocumentSchema)
// c.extendPermissionsProperties(AIDocumentSchema, 'ai_scenario')
// c.extendTranslationCoverageProperties(AIDocumentSchema)

module.exports = AIDocumentSchema
