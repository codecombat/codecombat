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

module.exports =
  'god:user-code-problem': c.object {required: ['problem']},
    problem: {type: 'object'}

  'god:non-user-code-problem': c.object {required: ['problem']},
    problem: {type: 'object'}

  'god:infinite-loop': c.object {required: ['firstWorld']},
    firstWorld: {type: 'boolean'}
    nonUserCodeProblem: {type: 'boolean'}

  'god:new-world-created': worldUpdatedEventSchema

  'god:streaming-world-updated': worldUpdatedEventSchema

  'god:goals-calculated': c.object {required: ['goalStates']},
    goalStates: goalStatesSchema
    preload: {type: 'boolean'}
    overallStatus: {type: ['string', 'null'], enum: ['success', 'failure', 'incomplete', null]}

  'god:world-load-progress-changed': c.object {required: ['progress']},
    progress: {type: 'number', minimum: 0, maximum: 1}

  'god:debug-world-load-progress-changed': c.object {required: ['progress']},
    progress: {type: 'number', minimum: 0, maximum: 1}

  'god:debug-value-return': c.object {required: ['key']},
    key: {type: 'string'}
    value: {}
