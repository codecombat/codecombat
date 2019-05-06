/* eslint-env jasmine */
import {
  interactiveDraggableOrderingSchema,
  elementOrderingSolutionSchema,
  singleSolutionSchema,
  classificationSolutionSchema
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
  const badInteractiveDraggableObject = {
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


