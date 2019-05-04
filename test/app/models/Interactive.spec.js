/* eslint-env jasmine */
import InteractivesSchema from '../../../app/schemas/models/interactives'
import Ajv from 'ajv'

const ajv = new Ajv({ schemaId: 'id' }) // If we want to use both draft-04 and draft-06/07 schemas then use { schemaId: 'auto' }
const interactivesObject = {
  labels: ['label1', 'label2'],
  elements: [{
    text: 'hello world',
    elementId: 'this-is-my-id!'
  }],
  solution: ['My first code solution', 'My second code solution']
}
const badInteractivesObject = {
  labels: { not: 'an array '},
  elements: [{ text: { not: 'just a string' }, elementId: ['not just a string'] }],
  solution: 'not an array'
}

describe('Interactives', () => {
  it('compiles the schema', () => {
    const validate = ajv.compile(InteractivesSchema)
    expect(typeof validate).toBe('function')
    expect(ajv.errors).toBe(null)
  })

  it('validates a correct object using the interactives schema', () => {
    const valid = ajv.validate(InteractivesSchema, interactivesObject)
    expect(valid).toBe(true)
  })

  it('fails to validate an incorrect object using the interactives schema', () => {
    const valid = ajv.validate(InteractivesSchema, badInteractivesObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })
})
