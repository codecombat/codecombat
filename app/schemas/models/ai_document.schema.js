// WARNING: This file is auto-generated from within AI HackStack. Do not edit directly.
// Instead, edit the corresponding Zod schema in the HackStack repo and run `npm run build` or `npm run build:schemas
//
// Last updated: 2023-12-04T11:56:21.103Z

const _ = require('lodash')
const c = require('./../schemas')

const AIDocumentSchema = c.object({
  title: 'AI Document',
  description: 'A code/image/whatever thing that is hacked on inside an AI project'
})

_.extend(AIDocumentSchema.properties, {
  source: {
    title: 'Source',
    type: 'object',
    description: 'The source of the document',
    format: 'document-by-type',
    additionalProperties: true,
    properties: {
      type: { type: 'string', title: 'Type', description: 'The type of document' },
      text: { type: 'string', title: 'Text', description: 'The document text source' },
      filePath: { type: 'string', title: 'File Path', description: 'The file path of the document' },
      blob: { type: 'string', title: 'Blob', description: 'The blob source of the document' },
      i18n: { type: 'object', format: 'i18n', props: ['text'], description: 'Help translate this property' }
    }
  }
})

AIDocumentSchema.required = ['source']

c.extendBasicProperties(AIDocumentSchema, 'ai_document')
c.extendSearchableProperties(AIDocumentSchema, 'ai_document')
c.extendPatchableProperties(AIDocumentSchema, 'ai_document')
c.extendVersionedProperties(AIDocumentSchema, 'ai_document')
c.extendTranslationCoverageProperties(AIDocumentSchema, 'ai_document')

module.exports = AIDocumentSchema
