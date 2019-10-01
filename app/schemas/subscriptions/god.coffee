c = require 'schemas/schemas'

goalStatesSchema =
  type: 'object'
  additionalProperties:
    type: 'object'
    required: ['status']
    properties:
      status:
        oneOf: [
          {type: 'null'}
          {type: 'string', enum: ['success', 'failure', 'incomplete']}
        ]
      keyFrame:
        oneOf: [
          {type: 'integer', minimum: 0}
          {type: 'string', enum: ['end']}
        ]
      team: {type: ['null', 'string', 'undefined']}

worldUpdatedEventSchema = c.object {required: ['world', 'firstWorld', 'goalStates', 'team', 'firstChangedFrame']},
  world: {type: 'object'}
  firstWorld: {type: 'boolean'}
  goalStates: goalStatesSchema
  team: {type: 'string'}
  firstChangedFrame: {type: 'integer', minimum: 0}
  finished: {type: 'boolean'}
  god: {type: 'object'}
  keyValueDb: {type: 'object'}

module.exports =
  'god:user-code-problem': c.object {required: ['problem', 'god']},
    god: {type: 'object'}
    problem: {type: 'object'}

  'god:non-user-code-problem': c.object {required: ['problem', 'god']},
    god: {type: 'object'}
    problem: {type: 'object'}

  'god:infinite-loop': c.object {required: ['firstWorld', 'god']},
    god: {type: 'object'}
    firstWorld: {type: 'boolean'}
    nonUserCodeProblem: {type: 'boolean'}

  'god:new-world-created': worldUpdatedEventSchema

  'god:streaming-world-updated': worldUpdatedEventSchema

  'god:new-html-goal-states': c.object {required: ['goalStates', 'overallStatus']},
    goalStates: goalStatesSchema
    overallStatus: {type: ['string', 'null'], enum: ['success', 'failure', 'incomplete', null]}

  'god:goals-calculated': c.object {required: ['goalStates', 'god']},
    god: {type: 'object'}
    goalStates: goalStatesSchema
    preload: {type: 'boolean'}
    overallStatus: {type: ['string', 'null'], enum: ['success', 'failure', 'incomplete', null]}
    totalFrames: {type: ['integer', 'undefined']}
    lastFrameHash: {type: ['number', 'undefined']}
    simulationFrameRate: {type: ['number', 'undefined']}

  'god:world-load-progress-changed': c.object {required: ['progress', 'god']},
    god: {type: 'object'}
    progress: {type: 'number', minimum: 0, maximum: 1}

  'god:debug-world-load-progress-changed': c.object {required: ['progress', 'god']},
    god: {type: 'object'}
    progress: {type: 'number', minimum: 0, maximum: 1}

  'god:debug-value-return': c.object {required: ['key', 'god']},
    god: {type: 'object'}
    key: {type: 'string'}
    value: {}
