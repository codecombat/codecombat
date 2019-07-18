/* eslint-env jasmine */
import {
  elementOrderingSolutionSchema,
  singleSolutionSchema,
  classificationSolutionSchema
} from '../../../app/schemas/models/interactives/common/solutions.schema'
import {
  interactiveDraggableOrderingSchema,
  interactiveInsertCodeSchema,
  interactiveDraggableClassificationSchema,
  interactiveMultipleChoiceSchema,
  interactiveFillInCodeSchema,
  interactiveDraggableStatementCompletionSchema
} from '../../../app/schemas/models/interactives/common/interactive_types.schema'
import interactiveSchema from '../../../app/schemas/models/interactives/interactive.schema'

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

const interactiveDraggableObject = {
  labels: [
    {
      text: 'label1',
      textStyleCode: true
    }, {
      text: 'label2'
    }],
  elements: [{
    text: 'element 1',
    elementId: '0123456789abcdefghijklmn'
  }, {
    text: 'element 2',
    textStyleCode: true,
    elementId: '1123456789abcdefghijklmn'
  }],
  solution: ['1123456789abcdefghijklmn', '0123456789abcdefghijklmn']
}

const interactiveInsertCodeObject = {
  starterCode: 'run ',
  choices: [{
    text: 'AWAY!!!',
    choiceId: '0123456789abcdefghijklmn',
    triggerArt: 'running-away'
  }],
  solution: '0123456789abcdefghijklmn'
}

const interactiveDraggableClassificationObject = {
  categories: [{
    categoryId: 'c123456789abcdefghijklmn',
    text: 'Something draggable'
  }],
  elements: [{
    text: 'Draggable number one',
    elementId: '0123456789abcdefghijklmn'
  }],
  solution: [{
    categoryId: 'c123456789abcdefghijklmn',
    elements: ['0123456789abcdefghijklmn']
  }]
}

const interactiveMultipleChoiceObject = {
  choices: [{
    text: 'It is dangerous to go alone',
    choiceId: '0123456789abcdefghijklmn'
  }],
  solution: '0123456789abcdefghijklmn'
}

const interactiveFillInCodeObject = {
  starterCode: 'console.log("hello world!")',
  commonResponses: [{
    text: 'Hi world',
    responseId: '0123456789abcdefghijklmn',
    triggerArt: 'globe'
  }],
  solution: '0123456789abcdefghijklmn'
}

const interactiveDraggableStatementCompletionObject = {
  labels: [{
    text: 'hello'
  }, {
    text: 'world',
    textStyleCode: true
  }],
  elements: [{
    text: 'world',
    elementId: '0123456789abcdefghijklmn'
  }, {
    text: 'hello',
    elementId: '1123456789abcdefghijklmn'
  }],
  solution: ['1123456789abcdefghijklmn', '0123456789abcdefghijklmn']
}

describe('Interactive', () => {
  describe('interactive solutions schema tests', () => {
    describe('elementOrderingSolutionSchema', () => {
      const elementOrderingObject = ['0123456789abcdefghijklmn', '1123456789abcdefghijklmn']
      const badElementOrderingObject = { 'string in object': 'hello' }
      schemaCompileTest(elementOrderingSolutionSchema)
      schemaValidateObjectTest(elementOrderingSolutionSchema, elementOrderingObject)
      schemaValidateBadObjectTest(elementOrderingSolutionSchema, badElementOrderingObject)
    })

    describe('singleSolutionSchema', () => {
      const singleSolutionObject = '0123456789abcdefghijklmn'
      const badSingleSolutionObject = 42
      schemaCompileTest(singleSolutionSchema)
      schemaValidateObjectTest(singleSolutionSchema, singleSolutionObject)
      schemaValidateBadObjectTest(singleSolutionSchema, badSingleSolutionObject)
    })

    describe('classificationSolutionSchema', () => {
      const classificationSolutionObject = [{ categoryId: 'c123456789abcdefghijklmn', elements: ['0123456789abcdefghijklmn', '1123456789abcdefghijklmn'] }]
      const badClassificationSolutionObject = { answer: 'wrong' }
      const badClassificationSolutionPropertiesObject = [{ categoryId: 42, elements: 'element1' }]
      schemaCompileTest(classificationSolutionSchema)
      schemaValidateObjectTest(classificationSolutionSchema, classificationSolutionObject)
      schemaValidateBadObjectTest(classificationSolutionSchema, badClassificationSolutionObject)
      schemaValidateBadPropertyTest(classificationSolutionSchema, badClassificationSolutionPropertiesObject)
    })
  })

  describe('interactive-type schema tests', () => {
    describe('interactiveDraggableOrderingSchema', () => {
      const badInteractiveDraggableObject = 'wrong'
      const badInteractiveDraggablePropertiesObject = {
        labels: { not: 'an array' },
        elements: [{ text: { not: 'just a string' }, elementId: ['not just a string'] }]
      }
      schemaCompileTest(interactiveDraggableOrderingSchema)
      schemaValidateObjectTest(interactiveDraggableOrderingSchema, interactiveDraggableObject)
      schemaValidateBadObjectTest(interactiveDraggableOrderingSchema, badInteractiveDraggableObject)
      schemaValidateBadPropertyTest(interactiveDraggableOrderingSchema, badInteractiveDraggablePropertiesObject)
    })

    describe('interactiveInsertCodeSchema', () => {
      const badInteractiveInsertCodeObject = 'it is only a rabbit'
      const badInteractiveInsertCodePropertiesObject = {
        starterCode: 'monty python',
        choices: [{
          text: 42,
          choiceId: [42],
          triggerArt: { 'fail?': 'yep' }
        }]
      }
      schemaCompileTest(interactiveInsertCodeSchema)
      schemaValidateObjectTest(interactiveInsertCodeSchema, interactiveInsertCodeObject)
      schemaValidateBadObjectTest(interactiveInsertCodeSchema, badInteractiveInsertCodeObject)
      schemaValidateBadPropertyTest(interactiveInsertCodeSchema, badInteractiveInsertCodePropertiesObject)
    })

    describe('interactiveDraggableClassificationSchema', () => {
      const badInteractiveDraggableClassificationObject = ['something', 'draggable']
      const badInteractiveDraggableClassificationPropertiesObject = {
        categories: {
          categoryId: 'draggable-id',
          text: 'Something draggable'
        },
        elements: 'only one element'
      }
      schemaCompileTest(interactiveDraggableClassificationSchema)
      schemaValidateObjectTest(interactiveDraggableClassificationSchema, interactiveDraggableClassificationObject)
      schemaValidateBadObjectTest(interactiveDraggableClassificationSchema, badInteractiveDraggableClassificationObject)
      schemaValidateBadPropertyTest(interactiveDraggableClassificationSchema, badInteractiveDraggableClassificationPropertiesObject)
    })

    describe('interactiveMultipleChoiceSchema', () => {
      const badInteractiveMultipleChoiceObject = 'not an object'
      const badInteractiveMultipleChoicePropertiesObject = {
        choices: [{
          text: ['not just text'],
          choiceId: { not: 'a choiceId' }
        }]
      }
      schemaCompileTest(interactiveMultipleChoiceSchema)
      schemaValidateObjectTest(interactiveMultipleChoiceSchema, interactiveMultipleChoiceObject)
      schemaValidateBadObjectTest(interactiveMultipleChoiceSchema, badInteractiveMultipleChoiceObject)
      schemaValidateBadPropertyTest(interactiveMultipleChoiceSchema, badInteractiveMultipleChoicePropertiesObject)
    })

    describe('interactiveFillInCodeSchema', () => {
      const badInteractiveFillInCodeObject = ['not', 'an', 'object']
      const badInteractiveFillInCodePropertiesObject = {
        starterCode: {
          language: ['javascript'],
          code: 42
        },
        commonResponses: { hello: 'world!' }
      }
      schemaCompileTest(interactiveFillInCodeSchema)
      schemaValidateObjectTest(interactiveFillInCodeSchema, interactiveFillInCodeObject)
      schemaValidateBadObjectTest(interactiveFillInCodeSchema, badInteractiveFillInCodeObject)
      schemaValidateBadPropertyTest(interactiveFillInCodeSchema, badInteractiveFillInCodePropertiesObject)
    })

    describe('interactiveDraggableStatementCompletionSchema', () => {
      const badInteractiveDraggableStatementCompletionObject = ['not', 'correct']
      const badInteractiveDraggableStatementCompletionPropertiesObject = {
        labels: 'not an array',
        elements: [{ text: { not: 'a string' }, elementId: 42 }]
      }
      schemaCompileTest(interactiveDraggableStatementCompletionSchema)
      schemaValidateObjectTest(interactiveDraggableStatementCompletionSchema, interactiveDraggableStatementCompletionObject)
      schemaValidateBadObjectTest(interactiveDraggableStatementCompletionSchema, badInteractiveDraggableStatementCompletionObject)
      schemaValidateBadPropertyTest(interactiveDraggableStatementCompletionSchema, badInteractiveDraggableStatementCompletionPropertiesObject)
    })
  })

  describe('interactive overall schema', () => {
    const interactivesObject = {
      interactiveType: 'draggable-ordering',
      promptText: 'prompt text for interactive',
      draggableOrderingData: interactiveDraggableObject,
      unitCodeLanguage: 'python',
      documentation: {
        specificArticles: [ {
          name: 'Learning Goals',
          body: 'Practice the programming concepts.'
        }]
      }
    }
    const badInteractivesObjectProperties = {
      interactiveType: 'draggable-ordering',
      promptText: 'prompt text for interactive',
      insertCodeData: interactiveInsertCodeObject, // incorrect data schema
      unitCodeLanguage: 'python'
    }
    const badInteractivesObjectData = {
      interactiveType: 'draggable-ordering',
      promptText: 'prompt text for interactive',
      draggableOrderingData: interactiveInsertCodeObject, // incorrect data schema
      unitCodeLanguage: 'python'
    }
    const badInsertCodeInteractivesObject = {
      interactiveType: 'insert-code',
      promptText: 'prompt text for interactive',
      insertCodeData: interactiveInsertCodeObject,
      unitCodeLanguage: 'both' // only python/javascript valid for insert code
    }

    schemaCompileTest(interactiveSchema)
    schemaValidateObjectTest(interactiveSchema, interactivesObject)
    schemaValidateBadObjectTest(interactiveSchema, badInsertCodeInteractivesObject)
    schemaValidateBadPropertyTest(interactiveSchema, badInteractivesObjectProperties)
    schemaValidateBadPropertyTest(interactiveSchema, badInteractivesObjectData)
  })
})
