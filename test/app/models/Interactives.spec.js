/* eslint-env jasmine */
import {
  interactiveDraggableOrderingSchema,
  elementOrderingSolutionSchema,
  singleSolutionSchema,
  classificationSolutionSchema,
  interactiveInsertCodeSchema,
  interactiveDraggableClassificationSchema,
  interactiveMultipleChoiceSchema,
  interactiveFillInCodeSchema,
  interactiveDraggableStatementCompletionSchema,
  draggableOrderingSubmissionSchema,
  insertCodeSubmissionSchema,
  draggableClassificationSubmissionSchema,
  multipleChoiceSubmissionSchema
} from '../../../app/schemas/models/interactives.schema'
import Ajv from 'ajv'

const ajv = new Ajv({ schemaId: 'id' }) // If we want to use both draft-04 and draft-06/07 schemas then use { schemaId: 'auto' }

describe('interactiveDraggableOrderingSchema', () => {
  const interactiveDraggableObject = {
    labels: ['label1', 'label2'],
    elements: [{
      text: 'hello world',
      elementId: 'this-is-my-id!'
    }]
  }
  const badInteractiveDraggableObject = 'wrong'
  const badInteractiveDraggablePropertiesObject = {
    labels: { not: 'an array '},
    elements: [{ text: { not: 'just a string' }, elementId: ['not just a string'] }]
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

describe('interactiveMultipleChoiceSchema', () => {
  const interactiveMultipleChoiceObject = {
    choices: [{
      text: 'It is dangerous to go alone',
      choiceId: 'wooden-sword'
    }]
  }
  const badInteractiveMultipleChoiceObject = 'not an object'
  const badInteractiveMultipleChoicePropertiesObject = {
    choices: [{
      text: ['not just text'],
      choiceId: { not: 'a choiceId' }
    }]
  }

  it('compiles the schema', () => {
    const validate = ajv.compile(interactiveMultipleChoiceSchema)
    expect(typeof validate).toBe('function')
    expect(ajv.errors).toBe(null)
  })

  it('validates a correct object', () => {
    const valid = ajv.validate(interactiveMultipleChoiceSchema, interactiveMultipleChoiceObject)
    expect(valid).toBe(true)
    expect(ajv.errors).toBe(null)
  })

  it('fails to validate an incorrect object', () => {
    const valid = ajv.validate(interactiveMultipleChoiceSchema, badInteractiveMultipleChoiceObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })

  it('fails to validate incorrect properties on object', () => {
    const valid = ajv.validate(interactiveMultipleChoiceSchema, badInteractiveMultipleChoicePropertiesObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })
})

describe('interactiveFillInCodeSchema', () => {
  const interactiveFillInCodeObject = {
    starterCode: {
      language: 'javascript', // or 'python'
      code: 'console.log("hello world!")'
    },
    commonResponses: [{
      text: 'Hi world',
      responseId: 'hi-world',
      triggerArt: 'globe'
    }]
  }
  const badInteractiveFillInCodeObject = ['not', 'an', 'object']
  const badInteractiveFillInCodePropertiesObject = {
    starterCode: {
      language: ['javascript'],
      code: 42
    },
    commonResponses: { hello: 'world!' }
  }

  it('compiles the schema', () => {
    const validate = ajv.compile(interactiveFillInCodeSchema)
    expect(typeof validate).toBe('function')
    expect(ajv.errors).toBe(null)
  })

  it('validates a correct object', () => {
    const valid = ajv.validate(interactiveFillInCodeSchema, interactiveFillInCodeObject)
    expect(valid).toBe(true)
    expect(ajv.errors).toBe(null)
  })

  it('fails to validate an incorrect object', () => {
    const valid = ajv.validate(interactiveFillInCodeSchema, badInteractiveFillInCodeObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })

  it('fails to validate incorrect properties on object', () => {
    const valid = ajv.validate(interactiveFillInCodeSchema, badInteractiveFillInCodePropertiesObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })
})

describe('interactiveDraggableStatementCompletionSchema', () => {
  const interactiveDraggableStatementCompletionObject = {
    labels: ['hello', 'world'],
    elements: [{
      text: 'hello world',
      elementId: 'hello-world'
    }]
  }
  const badInteractiveDraggableStatementCompletionObject = ['not', 'correct']
  const badInteractiveDraggableStatementCompletionPropertiesObject = {
    labels: 'not an array',
    elements: [{ text: { not: 'a string' }, elementId: 42 }]
  }

  beforeEach(() => {
    // TODO: Understand why errors persist through from the last test suite, here
    ajv.errors = null
  })

  it('compiles the schema', () => {
    const validate = ajv.compile(interactiveDraggableStatementCompletionSchema)
    expect(typeof validate).toBe('function')
    expect(ajv.errors).toBe(null)
  })

  it('validates a correct object', () => {
    const valid = ajv.validate(interactiveDraggableStatementCompletionSchema, interactiveDraggableStatementCompletionObject)
    expect(valid).toBe(true)
    expect(ajv.errors).toBe(null)
  })

  it('fails to validate an incorrect object', () => {
    const valid = ajv.validate(interactiveDraggableStatementCompletionSchema, badInteractiveDraggableStatementCompletionObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })

  it('fails to validate incorrect properties on object', () => {
    const valid = ajv.validate(interactiveDraggableStatementCompletionSchema, badInteractiveDraggableStatementCompletionPropertiesObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })
})

describe('draggableOrderingSubmissionSchema', () => {
  const draggableOrderingSubmissionObject = {
    submission: ['id-1', 'id-2']
  }
  const badDraggableOrderingSubmissionObject = 'not an array'
  const badDraggableOrderingSubmissionPropertiesObject = {
    submission: 'not an array'
  }

  it('compiles the schema', () => {
    const validate = ajv.compile(draggableOrderingSubmissionSchema)
    expect(typeof validate).toBe('function')
    expect(ajv.errors).toBe(null)
  })

  it('validates a correct object', () => {
    const valid = ajv.validate(draggableOrderingSubmissionSchema, draggableOrderingSubmissionObject)
    expect(valid).toBe(true)
    expect(ajv.errors).toBe(null)
  })

  it('fails to validate an incorrect object', () => {
    const valid = ajv.validate(draggableOrderingSubmissionSchema, badDraggableOrderingSubmissionObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })

  it('fails to validate incorrect properties on object', () => {
    const valid = ajv.validate(draggableOrderingSubmissionSchema, badDraggableOrderingSubmissionPropertiesObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })
})

describe('insertCodeSubmissionSchema', () => {
  const insertCodeSubmissionObject = {
    submission: 'id-1'
  }
  const badInsertCodeSubmissionObject = 42
  const badInsertCodeSubmissionPropertiesObject = {
    submission: {
      not: 'a string'
    }
  }

  it('compiles the schema', () => {
    const validate = ajv.compile(insertCodeSubmissionSchema)
    expect(typeof validate).toBe('function')
    expect(ajv.errors).toBe(null)
  })

  it('validates a correct object', () => {
    const valid = ajv.validate(insertCodeSubmissionSchema, insertCodeSubmissionObject)
    expect(valid).toBe(true)
    expect(ajv.errors).toBe(null)
  })

  it('fails to validate an incorrect object', () => {
    const valid = ajv.validate(insertCodeSubmissionSchema, badInsertCodeSubmissionObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })

  it('fails to validate incorrect properties on object', () => {
    const valid = ajv.validate(insertCodeSubmissionSchema, badInsertCodeSubmissionPropertiesObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })
})

describe('draggableClassificationSubmissionSchema', () => {
  const draggableClassificationSubmissionObject = {
    submission: [{
      categoryId: 'draggable-id',
      elements: ['element-1', 'element-2']
    }]
  }
  const badDraggableClassificationSubmissionObject = 42
  const badDraggableClassificationSubmissionPropertiesObject = {
    submission: [{
      categoryId: 42,
      elements: { not: 'an array' }
    }]
  }

  it('compiles the schema', () => {
    const validate = ajv.compile(draggableClassificationSubmissionSchema)
    expect(typeof validate).toBe('function')
    expect(ajv.errors).toBe(null)
  })

  it('validates a correct object', () => {
    const valid = ajv.validate(draggableClassificationSubmissionSchema, draggableClassificationSubmissionObject)
    expect(valid).toBe(true)
    expect(ajv.errors).toBe(null)
  })

  it('fails to validate an incorrect object', () => {
    const valid = ajv.validate(draggableClassificationSubmissionSchema, badDraggableClassificationSubmissionObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })

  it('fails to validate incorrect properties on object', () => {
    const valid = ajv.validate(draggableClassificationSubmissionSchema, badDraggableClassificationSubmissionPropertiesObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })
})

describe('multipleChoiceSubmissionSchema', () => {
  const multipleChoiceSubmissionObject = {
    submission: 'id-1'
  }
  const badMultipleChoiceSubmissionObject = 42
  const badMultipleChoiceSubmissionPropertiesObject = {
    submission: {
      not: 'a string'
    }
  }

  beforeEach(() => {
    // TODO: Understand why errors persist through from the last test suite, here
    ajv.errors = null
  })

  it('compiles the schema', () => {
    const validate = ajv.compile(multipleChoiceSubmissionSchema)
    expect(typeof validate).toBe('function')
    expect(ajv.errors).toBe(null)
  })

  it('validates a correct object', () => {
    const valid = ajv.validate(multipleChoiceSubmissionSchema, multipleChoiceSubmissionObject)
    expect(valid).toBe(true)
    expect(ajv.errors).toBe(null)
  })

  it('fails to validate an incorrect object', () => {
    const valid = ajv.validate(multipleChoiceSubmissionSchema, badMultipleChoiceSubmissionObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })

  it('fails to validate incorrect properties on object', () => {
    const valid = ajv.validate(multipleChoiceSubmissionSchema, badMultipleChoiceSubmissionPropertiesObject)
    expect(valid).toBe(false)
    expect(ajv.errors.length).toBe(1)
  })
})
