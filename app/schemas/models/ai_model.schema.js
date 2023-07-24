const c = require('./../schemas')
const _ = require('lodash')

const AIModelSchema = c.object({
  title: 'AI Model',
  description: 'A generative AI model'
})

_.extend(AIModelSchema.properties, {
  name: {
    type: 'string',
    description: 'The exact name of the model as used in API calls.'
  },
  family: c.shortString({
    enum: ['ChatGPT', 'Stable Diffusion'],
    title: 'Family',
    description: 'The family of models this model belongs to, usually what people know it as.'
  }),
  description: {
    type: 'string',
    title: 'Description',
    description: 'A short description of the model and what it does.'
  },
})

c.extendBasicProperties(AIModelSchema, 'ai_model')
c.extendVersionedProperties(AIModelSchema, 'ai_model')
c.extendSearchableProperties(AIModelSchema)
c.extendPatchableProperties(AIModelSchema)
// c.extendPermissionsProperties(AIModelSchema, 'ai_model')

module.exports = AIModelSchema
