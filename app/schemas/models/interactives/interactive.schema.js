// Overall schema for interactives
// This schema uses features from json schema draft-07
// Use ajv to validate against this schema instead of legacy tv4 - See Interactive.spec.js

const interactiveTypeSchema = require('./common/interactive_types.schema')
const schema = require('../../schemas')

const interactiveSchema = {
  type: 'object',
  required: ['interactiveType', 'promptText', 'interactiveData', 'unitCodeLanguage'],
  properties: {
    interactiveType: {
      'enum': ['draggable-ordering', 'insert-code', 'draggable-classification', 'multiple-choice', 'fill-in-code', 'draggable-statement-completion']
    },
    promptText: { type: 'string' }
  },
  allOf: [
    {
      if: {
        'properties': { 'interactiveType': { 'const': 'draggable-ordering' } }
      },
      then: {
        'properties': {
          'interactiveData': interactiveTypeSchema.interactiveDraggableOrderingSchema,
          'unitCodeLanguage': { 'enum': ['python', 'javascript', 'both'] }
        }
      }
    },
    {
      if: {
        'properties': { 'interactiveType': { 'const': 'insert-code' } }
      },
      then: {
        'properties': {
          'interactiveData': interactiveTypeSchema.interactiveInsertCodeSchema,
          'unitCodeLanguage': { 'enum': ['python', 'javascript'] }
        }
      }
    },
    {
      if: {
        'properties': { 'interactiveType': { 'const': 'draggable-classification' } }
      },
      then: {
        'properties': {
          'interactiveData': interactiveTypeSchema.interactiveDraggableClassificationSchema,
          'unitCodeLanguage': { 'enum': ['python', 'javascript', 'both'] }
        }
      }
    },
    {
      if: {
        'properties': { 'interactiveType': { 'const': 'multiple-choice' } }
      },
      then: {
        'properties': {
          'interactiveData': interactiveTypeSchema.interactiveMultipleChoiceSchema,
          'unitCodeLanguage': { 'enum': ['python', 'javascript', 'both'] }
        }
      }
    },
    {
      if: {
        'properties': { 'interactiveType': { 'const': 'fill-in-code' } }
      },
      then: {
        'properties': {
          'interactiveData': interactiveTypeSchema.interactiveFillInCodeSchema,
          'unitCodeLanguage': { 'enum': ['python', 'javascript'] }
        }
      }
    },
    {
      if: {
        'properties': { 'interactiveType': { 'const': 'draggable-statement-completion' } }
      },
      then: {
        'properties': {
          'interactiveData': interactiveTypeSchema.interactiveDraggableStatementCompletionSchema,
          'unitCodeLanguage': { 'enum': ['python', 'javascript', 'both'] }
        }
      }
    }
  ]
}

schema.extendBasicPropertiesNew(interactiveSchema, 'interactive')
schema.extendNamedPropertiesNew(interactiveSchema)

module.exports = interactiveSchema
