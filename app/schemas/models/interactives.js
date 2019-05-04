import c from './../schemas'

// singleSolutionSchema = {type: 'string'}  // choiceId/responseId of the correct choice/response
// classificationSolutionSchema = {type : 'array', items: {type: 'object', properties: {
//       categoryId: {type: 'string'},
//       elements: {type: 'array', items: {type: 'string'}}  // list of elementIds belonging to the categoryId
//     }}}
// interactiveDraggableOrderingSchema = {
//   type: 'object',
//   properties: {
//     labels: {type: 'array', items: { type: 'string' }},
//     elements: {type: 'array', items: { type: 'object',
//         properties: {
//           text: {type: 'string'},
//           elementId: {type: 'string'}
//         }
//       }},
//     solution: elementOrderingSolutionSchema
//   }
// }
// interactiveInsertCodeSchema = {
//   type: 'object',
//   properties: {
//     starterCode: { type: 'object', properties: {
//         language: { "enum" : ["python", "javascript"] },  // only if unitCodeLanguage in overall schema is `both`, else should be same as unitCodeLanguage
//         code: {type: 'string'}
//       },
//       choices: {type: "array", items: {type: 'object', properties: {
//             text: {type:'string'},
//             choiceId: {type: 'string'},
//             triggerArt: {type: 'string'}
//           }}},
//       solution: singleSolutionSchema
//     }
//   }
//   interactiveDraggableClassificationSchema = {
//     type: 'object',
//     properties: {
//       categories: {type: 'array', items: {type: 'object', properties: {
//             categoryId: {type: 'string'},
//             text: {type: 'string'}
//           }}},
//       elements: {type: 'array', items: { type: 'object',
//           properties: {
//             text: {type: 'string'},
//             elementId: {type: 'string'}
//           }
//         }},
//       solution: classificationSolutionSchema
//     }
//   }
//
//   interactiveMultipleChoiceSchema = {
//     type: 'object',
//     properties: {
//       choices: {type: "array", items: {type: 'object', properties: {
//             text: {type:'string'},
//             choiceId: {type: 'string'}
//           }}},
//       solution: singleSolutionSchema
//     }
//   }
//
//   interactiveFillInCodeSchema = {
//     type: 'object',
//     properties: {
//       starterCode: { type: 'object', properties: {
//           language: { "enum" : ["python", "javascript"] },  // only if unitCodeLanguage in overall schema is `both`, else should be same as unitCodeLanguage
//           code: {type: 'string'}
//         },
//         commonResponses: {type: "array", items: {type: 'object', properties: {
//               text: {type:'string'},
//               responseId: {type: 'string'},
//               triggerArt: {type: 'string'}
//             }}},
//         solution: singleSolutionSchema
//       }
//     }
//
//     interactiveDraggableStatementCompletionSchema = {
//       type: 'object',
//       properties: _.extend({}, interactiveDraggableOrderingSchema.properties)
//     }
//
//
//       draggableOrderingSubmissionSchema = {
//         type: 'object',
//         properties: {
//           submission: interactiveDraggableOrderingSchema.properties.solution
//         }
//       }
//
//     insertCodeSubmissionSchema = {
//       type: 'object',
//       properties: {
//         submission: interactiveInsertCodeSchema.properties.solution
//       }
//     }
//
//     draggableClassificationSubmissionSchema = {
//       type: 'object',
//       properties: {
//         submission: interactiveDraggableClassificationSchema.properties.solution,
//       }
//     }
//
//     multipleChoiceSubmissionSchema = {
//       type: 'object',
//       properties: {
//         submission: interactiveMultipleChoiceSchema.properties.solution
//       }
//     }
//
//     fillInCodeSubmissionSchema = {
//       type: 'object',
//       properties: {
//         submission: interactiveFillInCodeSchema.properties.solution
//       }
//     }
//
//     draggableStatementCompletionSubmissionSchema = {
//       type: 'object',
//       properties: {
//         submission: interactiveDraggableStatementCompletionSchema.properties.solution
//       }
//     }
//
//
//
//     Interactive schema
//
//     const InteractiveSchema = {
//       type: 'object',
//       properties: {
//         interactiveType: {
//           "enum" : ["draggable-ordering", "insert-code", "draggable-classification", "multiple-choice", "fill-in-code", "draggable-statement-completion"]
//         },
//         feedbackList: { // TBD
//           type: 'array'
//         },
//         artAssets: {  // TBD
//           type: 'array'
//         },
//         promptText: {type: 'string'},
//         unitCodeLanguage: { "enum" : ["python", "javascript", "both"] }, // to allow content to be same/different for different languages
//         allOf: [
//           {
//             if: {
//               "properties": { "interactiveType": { "const": "draggable-ordering" } }
//             },
//             then: {
//               "properties": { "interactiveData": interactiveDraggableOrderingSchema }
//             }
//           },
//           {
//             if: {
//               "properties": { "interactiveType": { "const": "insert-code" } }
//             },
//             then: {
//               "properties": { "interactiveData": interactiveInsertCodeSchema }
//             }
//           },
//           {
//             if: {
//               "properties": { "interactiveType": { "const": "draggable-classification" } }
//             },
//             then: {
//               "properties": { "interactiveData": interactiveDraggableClassificationSchema }
//             }
//           },
//           {
//             if: {
//               "properties": { "interactiveType": { "const": "multiple-choice" } }
//             },
//             then: {
//               "properties": { "interactiveData": interactiveMultipleChoiceSchema }
//             }
//           },
//           {
//             if: {
//               "properties": { "interactiveType": { "const": "fill-in-code" } }
//             },
//             then: {
//               "properties": { "interactiveData": interactiveFillInCodeSchema }
//             }
//           },
//           {
//             if: {
//               "properties": { "interactiveType": { "const": "draggable-statement-completion" } }
//             },
//             then: {
//               "properties": { "interactiveData": interactiveDraggableStatementCompletionSchema }
//             }
//           }
//         ]
//       }
//     }
//
//
//
//     Interactive Session Schema
//
//     Validation to be done:
//     finalSubmission should exist only if complete: true
//
// const InteractiveSessionSchema = {
//   type: 'object',
//   properties: {
//     interactiveId: {type: 'string'},
//     interactiveType: {
//       "enum" : ["draggable-ordering", "insert-code", "draggable-classification", "multiple-choice", "fill-in-code", "draggable-statement-completion"]
//     },
//     userId: {type: 'string'},
//     sessionCodeLanguage: { "enum" : ["python", "javascript"] },  // save this from the course instance language
//     noOfSubmissions: {type: 'number'},
//     complete: {type: 'boolean' },
//     finalSubmission: submissionSchema,  // only if complete:true
//     firstSubmission: {type: 'object', properties: {
//         correct: {type: 'boolean' },
//         submission : submissionSchema,
//         if: {
//           "properties": { "interactiveType": { "enum": [ "draggable-classification", "draggable-ordering" ] }}
//         },
//         then: {
//           "properties": { "noOfCorrect": {type: 'number'} }
//         }
//       }
//     }
//
//     const submissionSchema = {
//       type: 'object',
//       properties: {
//         allOf: [
//           {
//             if: {
//               "properties": { "interactiveType": { "const": "draggable-ordering" } }
//             },
//             then: {
//               "properties": { "submission": draggableOrderingSubmissionSchema }
//             }
//           },
//           {
//             if: {
//               "properties": { "interactiveType": { "const": "insert-code" } }
//             },
//             then: {
//               "properties": { "submission": insertCodeSubmissionSchema }
//             }
//           },
//           {
//             if: {
//               "properties": { "interactiveType": { "const": "draggable-classification" } }
//             },
//             then: {
//               "properties": { "submission": draggableClassificationSubmissionSchema }
//             }
//           },
//           {
//             if: {
//               "properties": { "interactiveType": { "const": "multiple-choice" } }
//             },
//             then: {
//               "properties": { "submission": multipleChoiceSubmissionSchema }
//             }
//           },
//           {
//             if: {
//               "properties": { "interactiveType": { "const": "fill-in-code" } }
//             },
//             then: {
//               "properties": { "submission": fillInCodeSubmissionSchema }
//             }
//           },
//           {
//             if: {
//               "properties": { "interactiveType": { "const": "draggable-statement-completion" } }
//             },
//             then: {
//               "properties": { "submission": draggableStatementCompletionSubmissionSchema }
//             }
//           }
//         ]
//       }
//     }
//

const elementOrderingSolutionSchema = { type: 'array', items: { type: 'string' }} // list of elementId in correct order

const interactiveDraggableOrderingSchema = {
  type: 'object',
  properties: {
    labels: { type: 'array', items: { type: 'string' }},
    elements: { type: 'array', items: { type: 'object',
        properties: {
          text: { type: 'string' },
          elementId: { type: 'string' }
        }
      }},
    solution: elementOrderingSolutionSchema
  }
}

export default interactiveDraggableOrderingSchema

// const InteractivesSchema = {
// }
//
//
// module.exports = InteractivesSchema
