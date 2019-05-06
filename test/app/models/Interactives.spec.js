/* eslint-env jasmine */
import {
  interactiveDraggableOrderingSchema,
  elementOrderingSolutionSchema,
  singleSolutionSchema,
  classificationSolutionSchema,
  interactiveInsertCodeSchema,
  interactiveDraggableClassificationSchema
} from '../../../app/schemas/models/interactives.schema'
import Ajv from 'ajv'

const ajv = new Ajv({ schemaId: 'id' }) // If we want to use both draft-04 and draft-06/07 schemas then use { schemaId: 'auto' }

describe('interactiveDraggableOrderingSchema', () => {
  const interactiveDraggableObject = {
    labels: ['label1', 'label2'],
    elements: [{
      text: 'hello world',
      elementId: 'this-is-my-id!'
    }],
    solution: ['My first code solution', 'My second code solution']
  }
  const badInteractiveDraggableObject = 'wrong'
  const badInteractiveDraggablePropertiesObject = {
    labels: { not: 'an array '},
    elements: [{ text: { not: 'just a string' }, elementId: ['not just a string'] }],
    solution: 'not an array'
  }

  it('compiles the schema', () => {
    const validate = ajv.compile(interactiveDraggableOrderingSchema)
    expect(typeof validate).toBe('function')
    expect(ajv.errors).toBe(null)
  })

  it('validates a correct object', () => {
    const valid = ajv.validate(interactiveDraggableOrderingSchema, interactiveDraggableObject)
    expect(valid).toBe(true)
    expect(ajv.errors).toBe(null)
  })

  it('fails to validate an incorrect object', () => {
    const valid = ajv.validate(interactiveDraggableOrderingSchema, badInteractiveDraggableObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })

  it('fails to validate incorrect properties on object', () => {
    const valid = ajv.validate(interactiveDraggableOrderingSchema, badInteractiveDraggablePropertiesObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })
})

describe('elementOrderingSolutionSchema', () => {
  const elementOrderingObject = ['string 1', 'string 2']
  const badElementOrderingObject = { 'string in object': 'hello' }

  it('compiles the schema', () => {
    const validate = ajv.compile(elementOrderingSolutionSchema)
    expect(typeof validate).toBe('function')
    expect(ajv.errors).toBe(null)
  })

  it('validates a correct object', () => {
    const valid = ajv.validate(elementOrderingSolutionSchema, elementOrderingObject)
    expect(valid).toBe(true)
    expect(ajv.errors).toBe(null)
  })

  it('fails to validate an incorrect object', () => {
    const valid = ajv.validate(elementOrderingSolutionSchema, badElementOrderingObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })
})

describe('singleSolutionSchema', () => {
  const singleSolutionObject = '42'
  const badSingleSolutionObject = 42

  it('compiles the schema', () => {
    const validate = ajv.compile(singleSolutionSchema)
    expect(typeof validate).toBe('function')
    expect(ajv.errors).toBe(null)
  })

  it('validates a correct object', () => {
    const valid = ajv.validate(singleSolutionSchema, singleSolutionObject)
    expect(valid).toBe(true)
    expect(ajv.errors).toBe(null)
  })

  it('fails to validate an incorrect object', () => {
    const valid = ajv.validate(singleSolutionSchema, badSingleSolutionObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })
})

describe('classificationSolutionSchema', () => {
  const interactiveInsertCodeObject = [{ categoryId: '42', elements: ['element1', 'element2'] }]
  const badInteractiveInsertCodeObject = { answer: 'wrong' }
  const badClassificationSolutionPropertiesObject = [{ categoryId: 42, elements: 'element1' }]

  it('compiles the schema', () => {
    const validate = ajv.compile(classificationSolutionSchema)
    expect(typeof validate).toBe('function')
    expect(ajv.errors).toBe(null)
  })

  it('validates a correct object', () => {
    const valid = ajv.validate(classificationSolutionSchema, interactiveInsertCodeObject)
    expect(valid).toBe(true)
    expect(ajv.errors).toBe(null)
  })

  it('fails to validate an incorrect object', () => {
    const valid = ajv.validate(classificationSolutionSchema, badInteractiveInsertCodeObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })

  it('fails to validate incorrect properties on object', () => {
    const valid = ajv.validate(classificationSolutionSchema, badClassificationSolutionPropertiesObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })
})

describe('interactiveInsertCodeSchema', () => {
  const interactiveInsertCodeObject = {
    starterCode: {
      language: 'python', // 'javascript'
      code: 'run '
    },
    choices: [{
      text: 'AWAY!!!',
      choiceId: 'away',
      triggerArt: 'running-away'
    }]
  }
  const badInteractiveInsertCodeObject = 'it is only a rabbit'
  const badInteractiveInsertCodePropertiesObject = {
    starterCode: {
      language: 'monty python'
    },
    choices: [{
      text: 42,
      choiceId: [42],
      triggerArt: { 'fail?': 'yep' }
    }]
  }

  it('compiles the schema', () => {
    const validate = ajv.compile(interactiveInsertCodeSchema)
    expect(typeof validate).toBe('function')
    expect(ajv.errors).toBe(null)
  })

  it('validates a correct object', () => {
    const valid = ajv.validate(interactiveInsertCodeSchema, interactiveInsertCodeObject)
    expect(valid).toBe(true)
    expect(ajv.errors).toBe(null)
  })

  it('fails to validate an incorrect object', () => {
    const valid = ajv.validate(interactiveInsertCodeSchema, badInteractiveInsertCodeObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })

  it('fails to validate incorrect properties on object', () => {
    const valid = ajv.validate(interactiveInsertCodeSchema, badInteractiveInsertCodePropertiesObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })
})


describe('interactiveDraggableClassificationSchema', () => {
  const interactiveDraggableClassificationObject = {
  // const badInteractiveDraggableClassificationPropertiesObject = {
    categories: [{
      categoryId: 'draggable-id',
      text: 'Something draggable'
    }],
    elements: [{
      text: 'Draggable number one',
      elementId: 'draggable-1'
    }]
  }
  const badInteractiveDraggableClassificationObject = ['something', 'draggable']
  const badInteractiveDraggableClassificationPropertiesObject = {
  // const interactiveDraggableClassificationObject = {
    categories: {
      categoryId: 'draggable-id',
      text: 'Something draggable'
    },
    elements: 'only one element'
  }

  it('compiles the schema', () => {
    const validate = ajv.compile(interactiveDraggableClassificationSchema)
    expect(typeof validate).toBe('function')
    expect(ajv.errors).toBe(null)
  })

  it('validates a correct object', () => {
    const valid = ajv.validate(interactiveDraggableClassificationSchema, interactiveDraggableClassificationObject)
    expect(valid).toBe(true)
    expect(ajv.errors).toBe(null)
  })

  it('fails to validate an incorrect object', () => {
    const valid = ajv.validate(interactiveDraggableClassificationSchema, badInteractiveDraggableClassificationObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })

  it('fails to validate incorrect properties on object', () => {
    const valid = ajv.validate(interactiveDraggableClassificationSchema, badInteractiveDraggableClassificationPropertiesObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })
})
