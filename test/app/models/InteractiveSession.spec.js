/* eslint-env jasmine */
import submissionSchema from '../../../app/schemas/models/interactives/common/submissions.schema'
import interactiveSessionSchema from '../../../app/schemas/models/interactives/interactive_session.schema'
import Ajv from 'ajv'
import { getAjvOptions } from 'ozaria/site/common/ozariaUtils'

function schemaCompileTest (schemaObject) {
  it('compiles successfully', () => {
    const ajv = new Ajv(getAjvOptions())
    const validate = ajv.compile(schemaObject)
    expect(typeof validate).toBe('function')
    expect(ajv.errors).toBe(null)
  })
}

function schemaValidateObjectTest (schemaObject, testObject) {
  it('validates a correct object', () => {
    const ajv = new Ajv(getAjvOptions())
    const valid = ajv.validate(schemaObject, testObject)
    expect(valid).toBe(true)
    expect(ajv.errors).toBe(null)
  })
}

function schemaValidateBadObjectTest (schemaObject, testObject) {
  it('fails to validate an incorrect object', () => {
    const ajv = new Ajv(getAjvOptions())
    const valid = ajv.validate(schemaObject, testObject)
    expect(valid).toBe(false)
    expect(ajv.errors).toBeDefined()
  })
}

function schemaValidateBadPropertyTest (schemaObject, testObject) {
  it('fails to validate incorrect properties on object', () => {
    const ajv = new Ajv(getAjvOptions())
    const valid = ajv.validate(schemaObject, testObject)
    expect(valid).toBe(false)
    expect(ajv.errors).toBeDefined()
  })
}

const draggableOrderingSubmissionObject = {
  submissionDate: new Date().toISOString(),
  correct: true,
  submittedSolution: ['0123456789abcdefghijklmn', '1123456789abcdefghijklmn'],
  correctElementsCount: 1
}

const insertCodeSubmissionObject = {
  submissionDate: new Date().toISOString(),
  correct: true,
  submittedSolution: '0123456789abcdefghijklmn'
}

const draggableClassificationSubmissionObject = {
  submissionDate: new Date().toISOString(),
  correct: true,
  submittedSolution: [{
    categoryId: 'c123456789abcdefghijklmn',
    elements: ['0123456789abcdefghijklmn', '1123456789abcdefghijklmn']
  }],
  correctElementsCount: 1
}

const multipleChoiceSubmissionObject = {
  submissionDate: new Date().toISOString(),
  correct: true,
  submittedSolution: '0123456789abcdefghijklmn'
}

const fillInCodeSubmissionObject = {
  submissionDate: new Date().toISOString(),
  correct: true,
  submittedSolution: '0123456789abcdefghijklmn'
}

const draggableStatementCompletionSubmissionObject = {
  submissionDate: new Date().toISOString(),
  correct: true,
  submittedSolution: ['0123456789abcdefghijklmn', '1123456789abcdefghijklmn']
}

describe('InteractiveSession', () => {
  describe('interactive submission schema for each type', () => {
    describe('draggableOrderingSubmissionSchema', () => {
      const badDraggableOrderingSubmissionObject = 'not an array'
      const badDraggableOrderingSubmissionPropertiesObject = {
        submittedSolution: 'not an array'
      }
      schemaCompileTest(submissionSchema.draggableOrderingSubmissionSchema)
      schemaValidateObjectTest(submissionSchema.draggableOrderingSubmissionSchema, draggableOrderingSubmissionObject)
      schemaValidateBadObjectTest(submissionSchema.draggableOrderingSubmissionSchema, badDraggableOrderingSubmissionObject)
      schemaValidateBadPropertyTest(submissionSchema.draggableOrderingSubmissionSchema, badDraggableOrderingSubmissionPropertiesObject)
    })

    describe('insertCodeSubmissionSchema', () => {
      const badInsertCodeSubmissionObject = 42
      const badInsertCodeSubmissionPropertiesObject = {
        submittedSolution: {
          not: 'a string'
        }
      }
      schemaCompileTest(submissionSchema.insertCodeSubmissionSchema)
      schemaValidateObjectTest(submissionSchema.insertCodeSubmissionSchema, insertCodeSubmissionObject)
      schemaValidateBadObjectTest(submissionSchema.insertCodeSubmissionSchema, badInsertCodeSubmissionObject)
      schemaValidateBadPropertyTest(submissionSchema.insertCodeSubmissionSchema, badInsertCodeSubmissionPropertiesObject)
    })

    describe('draggableClassificationSubmissionSchema', () => {
      const badDraggableClassificationSubmissionObject = 42
      const badDraggableClassificationSubmissionPropertiesObject = {
        submittedSolution: [{
          categoryId: 42,
          elements: { not: 'an array' }
        }]
      }
      schemaCompileTest(submissionSchema.draggableClassificationSubmissionSchema)
      schemaValidateObjectTest(submissionSchema.draggableClassificationSubmissionSchema, draggableClassificationSubmissionObject)
      schemaValidateBadObjectTest(submissionSchema.draggableClassificationSubmissionSchema, badDraggableClassificationSubmissionObject)
      schemaValidateBadPropertyTest(submissionSchema.draggableClassificationSubmissionSchema, badDraggableClassificationSubmissionPropertiesObject)
    })

    describe('multipleChoiceSubmissionSchema', () => {
      const badMultipleChoiceSubmissionObject = 42
      const badMultipleChoiceSubmissionPropertiesObject = {
        submittedSolution: {
          not: 'a string'
        }
      }
      schemaCompileTest(submissionSchema.multipleChoiceSubmissionSchema)
      schemaValidateObjectTest(submissionSchema.multipleChoiceSubmissionSchema, multipleChoiceSubmissionObject)
      schemaValidateBadObjectTest(submissionSchema.multipleChoiceSubmissionSchema, badMultipleChoiceSubmissionObject)
      schemaValidateBadPropertyTest(submissionSchema.multipleChoiceSubmissionSchema, badMultipleChoiceSubmissionPropertiesObject)
    })

    describe('fillInCodeSubmissionSchema', () => {
      const badFillInCodeSubmissionObject = 42
      const badFillInCodeSubmissionPropertiesObject = {
        submittedSolution: {
          not: 'a string'
        }
      }
      schemaCompileTest(submissionSchema.fillInCodeSubmissionSchema)
      schemaValidateObjectTest(submissionSchema.fillInCodeSubmissionSchema, fillInCodeSubmissionObject)
      schemaValidateBadObjectTest(submissionSchema.fillInCodeSubmissionSchema, badFillInCodeSubmissionObject)
      schemaValidateBadPropertyTest(submissionSchema.fillInCodeSubmissionSchema, badFillInCodeSubmissionPropertiesObject)
    })

    describe('draggableStatementCompletionSubmissionSchema', () => {
      const badDraggableStatementCompletionSubmissionObject = 'not an array'
      const badDraggableStatementCompletionSubmissionPropertiesObject = {
        submittedSolution: 'not an array'
      }
      schemaCompileTest(submissionSchema.draggableStatementCompletionSubmissionSchema)
      schemaValidateObjectTest(submissionSchema.draggableStatementCompletionSubmissionSchema, draggableStatementCompletionSubmissionObject)
      schemaValidateBadObjectTest(submissionSchema.draggableStatementCompletionSubmissionSchema, badDraggableStatementCompletionSubmissionObject)
      schemaValidateBadPropertyTest(submissionSchema.draggableStatementCompletionSubmissionSchema, badDraggableStatementCompletionSubmissionPropertiesObject)
    })
  })

  describe('overall interactive session schema', () => {
    const interactiveSessionObject = {
      interactiveId: 'i123456789abcdefghijklmn',
      userId: 'u123456789abcdefghijklmn',
      interactiveType: 'draggable-ordering',
      sessionCodeLanguage: 'python',
      submissions: [ draggableOrderingSubmissionObject ]
    }
    const badInteractiveSessionObjectProperties = {
      interactiveId: 'i123456789abcdefghijklmn',
      userId: 'u123456789abcdefghijklmn',
      interactiveType: 'draggable-ordering',
      sessionCodeLanguage: 'python',
      submissions: [ insertCodeSubmissionObject ] // incorrect submission schema
    }
    schemaCompileTest(interactiveSessionSchema)
    schemaValidateObjectTest(interactiveSessionSchema, interactiveSessionObject)
    schemaValidateBadPropertyTest(interactiveSessionSchema, badInteractiveSessionObjectProperties)
  })
})
