// Schemas for different types of submissions in various interactive_sessions.

const interactiveTypeSchema = require('./interactive_types.schema')
const schema = require('../../../schemas')

const draggableOrderingSubmissionSchema = {
  type: 'object',
  additionalProperties: false,
  properties: {
    submissionId: schema.objectId({ hidden: true }),
    submissionDate: schema.stringDate(),
    correct: { type: 'boolean' },
    submittedSolution: interactiveTypeSchema.interactiveDraggableOrderingSchema.properties.solution,
    correctElementsCount: { type: 'number' }
  }
}

const insertCodeSubmissionSchema = {
  type: 'object',
  additionalProperties: false,
  properties: {
    submissionId: schema.objectId({ hidden: true }),
    submissionDate: schema.stringDate(),
    correct: { type: 'boolean' },
    submittedSolution: interactiveTypeSchema.interactiveInsertCodeSchema.properties.solution
  }
}

const draggableClassificationSubmissionSchema = {
  type: 'object',
  additionalProperties: false,
  properties: {
    submissionId: schema.objectId({ hidden: true }),
    submissionDate: schema.stringDate(),
    correct: { type: 'boolean' },
    submittedSolution: interactiveTypeSchema.interactiveDraggableClassificationSchema.properties.solution,
    correctElementsCount: { type: 'number' }
  }
}

const multipleChoiceSubmissionSchema = {
  type: 'object',
  additionalProperties: false,
  properties: {
    submissionId: schema.objectId({ hidden: true }),
    submissionDate: schema.stringDate(),
    correct: { type: 'boolean' },
    submittedSolution: interactiveTypeSchema.interactiveMultipleChoiceSchema.properties.solution
  }
}

const fillInCodeSubmissionSchema = {
  type: 'object',
  additionalProperties: false,
  properties: {
    submissionId: schema.objectId({ hidden: true }),
    submissionDate: schema.stringDate(),
    correct: { type: 'boolean' },
    submittedSolution: interactiveTypeSchema.interactiveFillInCodeSchema.properties.solution
  }
}

const draggableStatementCompletionSubmissionSchema = {
  type: 'object',
  additionalProperties: false,
  properties: {
    submissionId: schema.objectId({ hidden: true }),
    submissionDate: schema.stringDate(),
    correct: { type: 'boolean' },
    submittedSolution: interactiveTypeSchema.interactiveDraggableStatementCompletionSchema.properties.solution
  }
}

module.exports = {
  draggableOrderingSubmissionSchema,
  insertCodeSubmissionSchema,
  draggableClassificationSubmissionSchema,
  multipleChoiceSubmissionSchema,
  fillInCodeSubmissionSchema,
  draggableStatementCompletionSubmissionSchema
}
