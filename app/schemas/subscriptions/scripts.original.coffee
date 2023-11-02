c = require 'schemas/schemas'

module.exports =
  'script:end-current-script': c.object {}

  'script:reset': c.object {}

  'script:ended': c.object {required: ['scriptID']},
    scriptID: {type: 'string'}

  'script:state-changed': c.object {required: ['currentScript', 'currentScriptOffset']},
    currentScript: {type: ['string', 'null']}
    currentScriptOffset: {type: 'integer', minimum: 0}

  'script:tick': c.object {required: ['scriptRunning', 'noteGroupRunning', 'scriptStates', 'timeSinceLastScriptEnded']},
    scriptRunning: {type: 'string'}
    noteGroupRunning: {type: 'string'}
    timeSinceLastScriptEnded: {type: 'number'}
    scriptStates:
      type: 'object'
      additionalProperties: c.object {title: 'Script State'},
        timeSinceLastEnded: {type: 'number', minimum: 0, description: 'seconds since this script ended last'}
        timeSinceLastTriggered: {type: 'number', minimum: 0, description: 'seconds since this script was triggered last'}

  'script:note-group-started': c.object {}

  'script:note-group-ended': c.object {}
