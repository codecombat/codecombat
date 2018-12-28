tv4 = require('tv4').tv4

module.exports = (options) ->
  tv4.validateMultiple options,
    "type": "object"
    additionalProperties: false
    properties:
      thisValue:
        required: false
      globals:
        type: 'array'
      functionName:
        type: 'string'
      functionParameters:
        type: ['array', 'undefined']
      yieldAutomatically:
        type: 'boolean'
      yieldConditionally:
        type: 'boolean'
      executionCosts:
        type: 'object'
      executionLimit:
        type: 'integer'
        minimum: 0
        description: 'If given and non-zero, user code will throw execution exceeded errors after using too many statements.'
      language:
        type: 'string'
        description: "Input language"
        minLength:1
        'enum': ['javascript', 'coffeescript', 'python', 'lua', 'java', 'html']
      languageVersion:
        type: ['string', 'null', 'undefined']  # TODO: remove option soon
      problems:
        type: ['object', 'undefined']
      problemContext:
        type: ['object', 'null', 'undefined']
      includeFlow:
        type: 'boolean'
        default: true
        description: "Whether to record control flow and variable values as user code executes."
      noSerializationInFlow:
        type: 'boolean'
        default: false
        description: "Whether to skip serializing variable values when recording variables in flow."
      noVariablesInFlow:
        type: 'boolean'
        default: false
        description: "Whether to skip capturing variable values at all when instrumenting flow."
      skipDuplicateUserInfoInFlow:
        type: 'boolean'
        default: false
        description: "Whether to skip recording calls with the same userInfo as the previous call when instrumenting flow."
      includeMetrics:
        type: 'boolean'
        default: true
      includeStyle:
        type: 'boolean'
        default: true
      protectAPI:
        type: ['boolean', 'null', 'undefined']
        default: false
      simpleLoops:
        type: 'boolean'
        default: false
        description: "Whether simple loops will be supported, per language.  E.g. 'loop()' will be transpiled as 'while(true)'."
      protectBuiltins:
        type: 'boolean'
        default: true
        description: 'Whether builtins will be protected and restored for enhanced security.'
      whileTrueAutoYield:
        type: 'boolean'
        default: false
        description: "Make while True loops automatically yield if no other yields"
      useInterpreter:  # TODO: remove option soon
        type: ['boolean', 'null', 'undefined']
        default: true
      debug:
        type: ['boolean']
        default: false
