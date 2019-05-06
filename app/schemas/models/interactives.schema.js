import _ from 'lodash'

const elementOrderingSolutionSchema = { type: 'array', items: { type: 'string' }} // list of elementId in correct order

const interactiveDraggableOrderingSchema = {
  type: 'object',
  properties: {
    labels: { type: 'array', items: { type: 'string' }},
    elements: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          text: { type: 'string' },
          elementId: { type: 'string' }
        }
      }
    },
    solution: elementOrderingSolutionSchema
  }
}

const singleSolutionSchema = { type: 'string' }  // choiceId/responseId of the correct choice/response

const classificationSolutionSchema = {
  type : 'array',
  items: {
    type: 'object',
    properties: {
      categoryId: { type: 'string' },
      elements: { type: 'array', items: { type: 'string' }}  // list of elementIds belonging to the categoryId
    }
  }
}

const interactiveInsertCodeSchema = {
  type: 'object',
  properties: {
    starterCode: {
      type: 'object',
      properties: {
        language: { "enum": ["python", "javascript"] },  // only if unitCodeLanguage in overall schema is `both`, else should be same as unitCodeLanguage
        code: { type: 'string' }
      },
      choices: {
        type: "array",
        items: {
          type: 'object',
          properties: {
            text: { type: 'string' },
            choiceId: { type: 'string' },
            triggerArt: { type: 'string' }
          }
        }
      }
    },
    solution: singleSolutionSchema
  }
}

const interactiveDraggableClassificationSchema = {
  type: 'object',
  properties: {
    categories: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          categoryId: { type: 'string' },
          text: { type: 'string' }
        }
      }
    },
    elements: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          text: { type: 'string' },
          elementId: { type: 'string' }
        }
      }
    },
    solution: classificationSolutionSchema
  }
}


const interactiveMultipleChoiceSchema = {
  type: 'object',
  properties: {
    choices: {
      type: "array",
      items: {
        type: 'object',
        properties: {
          text: { type: 'string' },
          choiceId: { type: 'string' }
        }
      }
    },
    solution: singleSolutionSchema
  }
}

const interactiveFillInCodeSchema = {
  type: 'object',
  properties: {
    starterCode: {
      type: 'object',
      properties: {
        language: { "enum": ["python", "javascript"] },  // only if unitCodeLanguage in overall schema is `both`, else should be same as unitCodeLanguage
        code: { type: 'string' }
      },
      commonResponses: {
        type: "array",
        items: {
          type: 'object',
          properties: {
            text: { type: 'string' },
            responseId: { type: 'string' },
            triggerArt: { type: 'string' }
          }
        }
      }
    },
    solution: singleSolutionSchema
  }
}

const interactiveDraggableStatementCompletionSchema = {
  type: 'object',
  properties: _.extend({}, interactiveDraggableOrderingSchema.properties)
}

const draggableOrderingSubmissionSchema = {
  type: 'object',
  properties: {
    submission: interactiveDraggableOrderingSchema.properties.solution
  }
}

const insertCodeSubmissionSchema = {
  type: 'object',
  properties: {
    submission: interactiveInsertCodeSchema.properties.solution
  }
}

const draggableClassificationSubmissionSchema = {
  type: 'object',
  properties: {
    submission: interactiveDraggableClassificationSchema.properties.solution,
  }
}

const multipleChoiceSubmissionSchema = {
  type: 'object',
  properties: {
    submission: interactiveMultipleChoiceSchema.properties.solution
  }
}

const fillInCodeSubmissionSchema = {
  type: 'object',
  properties: {
    submission: interactiveFillInCodeSchema.properties.solution
  }
}

const draggableStatementCompletionSubmissionSchema = {
  type: 'object',
  properties: {
    submission: interactiveDraggableStatementCompletionSchema.properties.solution
  }
}

// const InteractiveSchema = {
//   type: 'object',
//   properties: {
//     type: {
//       "enum" : ["draggable-ordering", "insert-code", "draggable-classification", "multiple-choice", "fill-in-code", "draggable-statement-completion"]
//     },
//     feedbackList: { // TBD
//       type: 'array'
//     },
//     artAssets: {  // TBD
//       type: 'array'
//     },
//     promptText: {type: 'string'},
//     unitCodeLanguage: { "enum" : ["python", "javascript", "both"] }, // to allow content to be same/different for different languages
//     allOf: [
//       {
//         if: {
//           "properties": { "type": { "const": "draggable-ordering" } }
//         },
//         then: {
//           "properties": { "interactiveData": interactiveDraggableOrderingSchema }
//         }
//       },
//       {
//         if: {
//           "properties": { "type": { "const": "insert-code" } }
//         },
//         then: {
//           "properties": { "interactiveData": interactiveInsertCodeSchema }
//         }
//       },
//       {
//         if: {
//           "properties": { "type": { "const": "draggable-classification" } }
//         },
//         then: {
//           "properties": { "interactiveData": interactiveDraggableClassificationSchema }
//         }
//       },
//       {
//         if: {
//           "properties": { "type": { "const": "multiple-choice" } }
//         },
//         then: {
//           "properties": { "interactiveData": interactiveMultipleChoiceSchema }
//         }
//       },
//       {
//         if: {
//           "properties": { "type": { "const": "fill-in-code" } }
//         },
//         then: {
//           "properties": { "interactiveData": interactiveFillInCodeSchema }
//         }
//       },
//       {
//         if: {
//           "properties": { "type": { "const": "draggable-statement-completion" } }
//         },
//         then: {
//           "properties": { "interactiveData": interactiveDraggableStatementCompletionSchema }
//         }
//       }
//     ]
//   }
// }
//
// const submissionSchema = {
//   type: 'object',
//   properties: {
//     allOf: [
//       {
//         if: {
//           "properties": { "type": { "const": "draggable-ordering" } }
//         },
//         then: {
//           "properties": { "submission": draggableOrderingSubmissionSchema }
//         }
//       },
//       {
//         if: {
//           "properties": { "type": { "const": "insert-code" } }
//         },
//         then: {
//           "properties": { "submission": insertCodeSubmissionSchema }
//         }
//       },
//       {
//         if: {
//           "properties": { "type": { "const": "draggable-classification" } }
//         },
//         then: {
//           "properties": { "submission": draggableClassificationSubmissionSchema }
//         }
//       },
//       {
//         if: {
//           "properties": { "type": { "const": "multiple-choice" } }
//         },
//         then: {
//           "properties": { "submission": multipleChoiceSubmissionSchema }
//         }
//       },
//       {
//         if: {
//           "properties": { "type": { "const": "fill-in-code" } }
//         },
//         then: {
//           "properties": { "submission": fillInCodeSubmissionSchema }
//         }
//       },
//       {
//         if: {
//           "properties": { "type": { "const": "draggable-statement-completion" } }
//         },
//         then: {
//           "properties": { "submission": draggableStatementCompletionSubmissionSchema }
//         }
//       }
//     ]
//   }
// }
//
// // Interactive Session Schema
// //
// // Validation to be done:
// // finalSubmission should exist only if complete: true
//
// const interactiveSessionSchema = {
//   type: 'object',
//   properties: {
//     interactiveId: { type: 'string' },
//     type: {
//       "enum": ["draggable-ordering", "insert-code", "draggable-classification", "multiple-choice", "fill-in-code", "draggable-statement-completion"]
//     },
//     userId: { type: 'string' },
//     sessionCodeLanguage: { "enum": ["python", "javascript"] },  // save this from the course instance language
//     noOfSubmissions: { type: 'number' },
//     complete: { type: 'boolean' },
//     finalSubmission: submissionSchema,  // only if complete:true
//     firstSubmission: {
//       type: 'object', properties: {
//         correct: { type: 'boolean' },
//         submission: submissionSchema,
//         if: {
//           "properties": { "type": { "enum": ["draggable-classification", "draggable-ordering"] }}
//         },
//         then: {
//           "properties": { "noOfCorrect": { type: 'number' }}
//         }
//       }
//     }
//   }
// }

export {
  // Solution
  elementOrderingSolutionSchema,
  singleSolutionSchema,
  classificationSolutionSchema,

  // Interactive
  interactiveDraggableOrderingSchema,
  interactiveInsertCodeSchema,
  interactiveDraggableClassificationSchema,
  interactiveMultipleChoiceSchema,
  interactiveFillInCodeSchema,
  interactiveDraggableStatementCompletionSchema,

  // Submission
  draggableOrderingSubmissionSchema,
  insertCodeSubmissionSchema,
  draggableClassificationSubmissionSchema,
  multipleChoiceSubmissionSchema,
  fillInCodeSubmissionSchema,
  draggableStatementCompletionSubmissionSchema,

  // Combined
  // interactiveSchema,
  // submissionSchema,
  // interactiveSessionSchema
}
