// WARNING: This file is auto-generated from within AI HackStack. Do not edit directly.
// Instead, edit the corresponding Zod schema in the HackStack repo and run `npm run build` or `npm run build:schemas
//
// Last updated: 2023-12-04T11:56:21.103Z

const _ = require('lodash')
const c = require('./../schemas')

const AIModelSchema = c.object({
  title: 'AI Model',
  description: 'A generative AI model'
})

_.extend(AIModelSchema.properties, {
  name: { title: 'Name', type: 'string', description: 'The precise name of the model, used in API calls' },
  family: {
    title: 'Family',
    type: 'string',
    description: 'The common name for the model or the family of models it is in',
    enum: ['ChatGPT', 'Stable Diffusion', 'Claude']
  },
  description: {
    title: 'Description',
    type: 'string',
    description: 'A short explanation of what this model does',
    maxLength: 2000
  }
})

AIModelSchema.required = ['name', 'family']

c.extendBasicProperties(AIModelSchema, 'ai_model')
c.extendVersionedProperties(AIModelSchema, 'ai_model')
c.extendSearchableProperties(AIModelSchema, 'ai_model')
c.extendPatchableProperties(AIModelSchema, 'ai_model')

module.exports = AIModelSchema
