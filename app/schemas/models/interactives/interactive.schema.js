// Overall schema for interactives
// This schema uses features from json schema draft-07
// Use ajv to validate against this schema instead of legacy tv4 - See Interactive.spec.js

const interactiveTypeSchema = require('./common/interactive_types.schema')
const schema = require('../../schemas')

const interactiveSchema = {
  type: 'object',
  properties: {
    interactiveType: {
      'enum': ['draggable-ordering', 'insert-code', 'draggable-classification', 'multiple-choice', 'fill-in-code', 'draggable-statement-completion'],
      title: 'Type of interactive'
    },
    promptText: { type: 'string', title: 'Prompt text' },
    draggableOrderingData: interactiveTypeSchema.interactiveDraggableOrderingSchema,
    insertCodeData: interactiveTypeSchema.interactiveInsertCodeSchema,
    draggableClassificationData: interactiveTypeSchema.interactiveDraggableClassificationSchema,
    multipleChoiceData: interactiveTypeSchema.interactiveMultipleChoiceSchema,
    fillInCodeData: interactiveTypeSchema.interactiveFillInCodeSchema,
    draggableStatementCompletionData: interactiveTypeSchema.interactiveDraggableStatementCompletionSchema,
    unitCodeLanguage: { 'enum': ['python', 'javascript', 'both'], title: 'Programming Language' },
    i18n: { type: 'object', format: 'i18n', props: ['promptText'], description: 'Help translate this interactive.' },
    defaultArtAsset: { type: 'string', format: 'image-file', title: 'Default Art Asset' }
  },
  allOf: [
    {
      if: {
        'properties': { 'interactiveType': { 'const': 'draggable-ordering' } }
      },
      then: {
        'properties': {
          'insertCodeData': { type: 'null' },
          'draggableClassificationData': { type: 'null' },
          'multipleChoiceData': { type: 'null' },
          'fillInCodeData': { type: 'null' },
          'draggableStatementCompletionData': { type: 'null' },
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
          'draggableOrderingData': { type: 'null' },
          'draggableClassificationData': { type: 'null' },
          'multipleChoiceData': { type: 'null' },
          'fillInCodeData': { type: 'null' },
          'draggableStatementCompletionData': { type: 'null' },
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
          'draggableOrderingData': { type: 'null' },
          'insertCodeData': { type: 'null' },
          'multipleChoiceData': { type: 'null' },
          'fillInCodeData': { type: 'null' },
          'draggableStatementCompletionData': { type: 'null' },
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
          'draggableOrderingData': { type: 'null' },
          'insertCodeData': { type: 'null' },
          'draggableClassificationData': { type: 'null' },
          'fillInCodeData': { type: 'null' },
          'draggableStatementCompletionData': { type: 'null' },
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
          'draggableOrderingData': { type: 'null' },
          'insertCodeData': { type: 'null' },
          'draggableClassificationData': { type: 'null' },
          'multipleChoiceData': { type: 'null' },
          'draggableStatementCompletionData': { type: 'null' },
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
          'draggableOrderingData': { type: 'null' },
          'insertCodeData': { type: 'null' },
          'draggableClassificationData': { type: 'null' },
          'multipleChoiceData': { type: 'null' },
          'fillInCodeData': { type: 'null' },
          'unitCodeLanguage': { 'enum': ['python', 'javascript', 'both'] }
        }
      }
    }
  ]
}

schema.extendBasicProperties(interactiveSchema, 'interactive')
schema.extendNamedProperties(interactiveSchema)

module.exports = interactiveSchema
