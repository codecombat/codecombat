module.exports =
  # TODO There should be a better way to divide these channels into smaller ones

  # TODO location is debatable
  'echo-self-wizard-sprite':
    {} # TODO schema

  'level:session-will-save':
    {} # TODO schema

  'level-loader:progress-changed':
    {} # TODO schema

  'level:shift-space-pressed':
    {} # TODO schema

  'level:escape-pressed':
    {} # TODO schema

  'level-enable-controls':
    {} # TODO schema

  'level-set-letterbox':
    {} # TODO schema

  'level:started':
    {} # TODO schema

  'level-set-debug':
    {} # TODO schema

  'level-set-grid':
    {} # TODO schema

  'tome:cast-spell':
    {} # TODO schema

  'level:restarted':
    {} # TODO schema

  'level-set-volume':
    {} # TODO schema

  'level-set-time':
    {} # TODO schema

  'level-select-sprite':
    {} # TODO schema

  'level-set-playing':
    {} # TODO schema

  'level:team-set':
    {} # TODO schema

  'level:docs-shown': {}

  'level:docs-hidden': {}

  'level:victory-hidden':
    {} # TODO schema

  'next-game-pressed':
    {} # TODO schema

  'end-current-script':
    {} # TODO schema

  'script:reset':
    {} # TODO schema

  'script:ended':
    {} # TODO schema

  'end-all-scripts': {}

  'script:state-changed':
    {} # TODO schema

  'script-manager:tick':
    type: 'object'
    additionalProperties: false
    properties:
      scriptRunning: {type: 'string'}
      noteGroupRunning: {type: 'string'}
      timeSinceLastScriptEnded: {type: 'number'}
      scriptStates:
        type: 'object'
        additionalProperties:
          title: 'Script State'
          type: 'object'
          additionalProperties: false
          properties:
            timeSinceLastEnded:
              type: 'number'
              description: 'seconds since this script ended last'
            timeSinceLastTriggered:
              type: 'number'
              description: 'seconds since this script was triggered last'

  'play-sound':
    {} # TODO schema

  # TODO refactor name
  'onLoadingViewUnveiled':
    {} # TODO schema

  'playback:manually-scrubbed':
    {} # TODO schema

  'change:editor-config':
    {} # TODO schema

  'restart-level':
    {} # TODO schema

  'play-next-level':
    {} # TODO schema

  'level-select-sprite':
    {} # TODO schema

  'level-toggle-grid':
    {} # TODO schema

  'level-toggle-debug':
    {} # TODO schema

  'level-toggle-pathfinding':
    {} # TODO schema

  'level-scrub-forward':
    {} # TODO schema

  'level-scrub-back':
    {} # TODO schema

  'level-show-victory':
    type: 'object'
    additionalProperties: false
    properties:
      showModal: {type: 'boolean'}

  'level-highlight-dom':
    type: 'object'
    additionalProperties: false
    properties:
      selector: {type: 'string'}
      delay: {type: 'number'}
      sides: {type: 'array', items: {'enum': ['left', 'right', 'top', 'bottom']}}
      offset: {type: 'object'}
      rotation: {type: 'number'}

  'goal-manager:new-goal-states':
    {} # TODO schema
