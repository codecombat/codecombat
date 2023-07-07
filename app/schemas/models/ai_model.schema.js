const c = require('./../schemas')
const _ = require('lodash')

const AIModelSchema = c.object({
  title: 'AI Model',
  description: 'A generative AI model'
})

c.extendNamedProperties(AIModelSchema)

_.extend(AIModelSchema.properties, {
  name: {
    type: 'string',
    title: 'Model Name',
    description: 'The common name for the model (e.g. "ChatGPT", "Stable Diffusion").'
  },
  description: {
    type: 'string',
    title: 'Model Description',
    description: 'A short description of the model and what it does.'
  },
  versions: {
    type: 'array',
    description: 'The specific versions of the model available'
  }
})

// AIModelSchema.definitions = { }
c.extendBasicProperties(AIModelSchema, 'ai_model')
// c.extendSearchableProperties(AIModelSchema)
// c.extendVersionedProperties(AIModelSchema, 'ai_model')
// c.extendPermissionsProperties(AIModelSchema, 'ai_model')
// c.extendPatchableProperties(AIModelSchema)
// c.extendTranslationCoverageProperties(AIModelSchema)

module.exports = AIModelSchema
