// Schemas for different types of solutions in various interactives

const schema = require('../../../schemas')

const elementOrderingSolutionSchema = {
  type: 'array',
  items: schema.stringID() // list of elements(elementId) in order
}

const singleSolutionSchema = schema.stringID() // choiceId/responseId of the correct choice/response

const classificationSolutionSchema = {
  type: 'array',
  items: {
    type: 'object',
    additionalProperties: false,
    properties: {
      categoryId: schema.stringID(),
      elements: { type: 'array', items: schema.stringID() } // list of elementIds belonging to the categoryId
    }
  }
}

module.exports = {
  elementOrderingSolutionSchema,
  singleSolutionSchema,
  classificationSolutionSchema
}
