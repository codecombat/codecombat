// Overall schema for interactive sessions.
// This schema uses features from json schema draft-07
// Use ajv to validate against this schema instead of legacy tv4 - See Interactive.spec.js

const submissionSchema = require('./common/submissions.schema')
const schema = require('../../schemas')

const interactiveSessionSchema = {
  type: 'object',
  required: ['interactiveId', 'interactiveType', 'userId', 'sessionCodeLanguage'],
  properties: {
    interactiveId: schema.objectId(),
    interactiveType: {
      'enum': ['draggable-ordering', 'insert-code', 'draggable-classification', 'multiple-choice', 'fill-in-code', 'draggable-statement-completion']
    },
    userId: schema.objectId(),
    sessionCodeLanguage: { 'enum': ['python', 'javascript'] }, // this will come from the course instance(for classroom) / me.aceConfig (for home users)
    submissionCount: { type: 'number' },
    complete: { type: 'boolean' },
    created: schema.stringDate(),
    changed: schema.stringDate(),
    dateFirstCompleted: schema.stringDate() // when first submitted correctly
  },
  allOf: [
    {
      if: {
        'properties': { 'interactiveType': { 'const': 'draggable-ordering' } }
      },
      then: {
        'properties': { 'submissions': { type: 'array', items: submissionSchema.draggableOrderingSubmissionSchema } }
      }
    },
    {
      if: {
        'properties': { 'interactiveType': { 'const': 'insert-code' } }
      },
      then: {
        'properties': { 'submissions': { type: 'array', items: submissionSchema.insertCodeSubmissionSchema } }
      }
    },
    {
      if: {
        'properties': { 'interactiveType': { 'const': 'draggable-classification' } }
      },
      then: {
        'properties': { 'submissions': { type: 'array', items: submissionSchema.draggableClassificationSubmissionSchema } }
      }
    },
    {
      if: {
        'properties': { 'interactiveType': { 'const': 'multiple-choice' } }
      },
      then: {
        'properties': { 'submissions': { type: 'array', items: submissionSchema.multipleChoiceSubmissionSchema } }
      }
    },
    {
      if: {
        'properties': { 'interactiveType': { 'const': 'fill-in-code' } }
      },
      then: {
        'properties': { 'submissions': { type: 'array', items: submissionSchema.fillInCodeSubmissionSchema } }
      }
    },
    {
      if: {
        'properties': { 'interactiveType': { 'const': 'draggable-statement-completion' } }
      },
      then: {
        'properties': { 'submissions': { type: 'array', items: submissionSchema.draggableStatementCompletionSubmissionSchema } }
      }
    }
  ]
}

schema.extendBasicProperties(interactiveSessionSchema, 'interactive.session')

module.exports = interactiveSessionSchema
