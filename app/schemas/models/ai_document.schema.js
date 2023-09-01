// WARNING: This file is auto-generated from within AI HackStack. Do not edit directly.
// Instead, edit the corresponding Zod schema in the HackStack repo and run `npm run build` or `npm run build:schemas
//
// Last updated: 2023-09-01T06:15:18.648Z

const _ = require('lodash')
const c = require('./../schemas')

const AIDocumentSchema = c.object({
  title: 'AI Document',
  description: 'A code/image/whatever thing that is hacked on inside an AI project',
})

_.extend(AIDocumentSchema.properties, {
  source: { title: 'Source', type: 'object', description: 'The source of the document', format: 'document-source' },
})

AIDocumentSchema.required = ['source']

c.extendBasicProperties(AIDocumentSchema, 'ai_document')
c.extendSearchableProperties(AIDocumentSchema, 'ai_document')
c.extendPatchableProperties(AIDocumentSchema, 'ai_document')
c.extendVersionedProperties(AIDocumentSchema, 'ai_document')

module.exports = AIDocumentSchema
