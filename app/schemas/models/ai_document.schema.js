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
<<<<<<< variant A
  type: { type: 'string', description: 'The file type (html, py, jpg, etc.)' },
  source: { type: 'string', description: 'The contents of the document', format: 'document-by-type' },
  i18n: { type: 'object', format: 'i18n', props: ['source'], description: 'Help translate this property' }
>>>>>>> variant B
  source: { title: 'Source', type: 'object', description: 'The source of the document', format: 'document-source' },
####### Ancestor
  type: { type: 'string', description: 'The file type (html, py, jpg, etc.)' },
  source: { type: 'string', description: 'The contents of the document', format: 'document-by-type' }
======= end
})

AIDocumentSchema.required = ['source']

c.extendBasicProperties(AIDocumentSchema, 'ai_document')
c.extendSearchableProperties(AIDocumentSchema, 'ai_document')
c.extendPatchableProperties(AIDocumentSchema, 'ai_document')
c.extendVersionedProperties(AIDocumentSchema, 'ai_document')
<<<<<<< variant A
// c.extendPermissionsProperties(AIDocumentSchema, 'ai_scenario')
c.extendTranslationCoverageProperties(AIDocumentSchema)
>>>>>>> variant B
####### Ancestor
// c.extendPermissionsProperties(AIDocumentSchema, 'ai_scenario')
// c.extendTranslationCoverageProperties(AIDocumentSchema)
======= end

module.exports = AIDocumentSchema
