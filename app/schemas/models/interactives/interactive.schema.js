// Overall schema for interactives
// This schema uses features from json schema draft-07
// Use ajv to validate against this schema instead of legacy tv4 - See Interactive.spec.js

const interactiveTypeSchema = require('./common/interactive_types.schema')
const schema = require('../../schemas')

// Specific articles schema for documentation (similar to levels)
const SpecificArticleSchema = schema.object()
schema.extendNamedProperties(SpecificArticleSchema)
SpecificArticleSchema.properties.body = { type: 'string', title: 'Content', description: 'The body content of the article, in Markdown.', format: 'markdown' }
SpecificArticleSchema.properties.i18n = { type: 'object', format: 'i18n', props: ['name', 'body'], description: 'Help translate this article' }
SpecificArticleSchema.displayProperty = 'name'

const interactiveSchema = {
  type: 'object',
  additionalProperties: false,
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
    defaultArtAsset: { type: 'string', format: 'image-file', title: 'Default Art Asset' },
    documentation: schema.object({
      title: 'Documentation',
      description: 'Documentation articles relating to this interactive.',
      'default': { specificArticles: [] },
      properties: {
        specificArticles: schema.array({ title: 'Specific Articles', description: 'Specific documentation articles that live only in this interactive.', uniqueItems: true }, SpecificArticleSchema)
      }
    })
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
