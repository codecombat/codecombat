const solutionSchema = require('./solutions.schema')
const schema = require('../../../schemas')

const interactiveDraggableOrderingSchema = {
  type: 'object',
  additionalProperties: false,
  properties: {
    labels: { type: 'array', items: { type: 'string' } },
    elements: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        properties: {
          text: { type: 'string' },
          elementId: schema.stringID()
        }
      }
    },
    solution: solutionSchema.elementOrderingSolutionSchema
  }
}

const interactiveInsertCodeSchema = {
  type: 'object',
  additionalProperties: false,
  properties: {
    starterCode: { type: 'string' }, // codeLanguage will be determined by unitCodeLanguage in interactives schema
    choices: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        properties: {
          text: { type: 'string' },
          choiceId: schema.stringID(),
          triggerArt: { type: 'string' }
        }
      }
    },
    solution: solutionSchema.singleSolutionSchema
  }
}

const interactiveDraggableClassificationSchema = {
  type: 'object',
  additionalProperties: false,
  properties: {
    categories: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        properties: {
          categoryId: schema.stringID(),
          text: { type: 'string' }
        }
      }
    },
    elements: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        properties: {
          text: { type: 'string' },
          elementId: schema.stringID()
        }
      }
    },
    solution: solutionSchema.classificationSolutionSchema
  }
}

const interactiveMultipleChoiceSchema = {
  type: 'object',
  additionalProperties: false,
  properties: {
    choices: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        properties: {
          text: { type: 'string' },
          choiceId: schema.stringID()
        }
      }
    },
    solution: solutionSchema.singleSolutionSchema
  }
}

const interactiveFillInCodeSchema = {
  type: 'object',
  additionalProperties: false,
  properties: {
    starterCode: { type: 'string' }, // codeLanguage will be determined by unitCodeLanguage in interactives schema
    commonResponses: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        properties: {
          text: { type: 'string' },
          responseId: schema.stringID(),
          triggerArt: { type: 'string' }
        }
      }
    },
    solution: solutionSchema.singleSolutionSchema
  }
}

const interactiveDraggableStatementCompletionSchema = {
  type: 'object',
  additionalProperties: false,
  properties: _.extend({}, interactiveDraggableOrderingSchema.properties)
}

module.exports = {
  interactiveDraggableOrderingSchema,
  interactiveInsertCodeSchema,
  interactiveDraggableClassificationSchema,
  interactiveMultipleChoiceSchema,
  interactiveFillInCodeSchema,
  interactiveDraggableStatementCompletionSchema
}
