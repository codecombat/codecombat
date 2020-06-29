c = require 'schemas/schemas'

module.exports =
  # TODO There should be a better way to divide these channels into smaller ones

  'level:session-will-save': c.object {required: ['session']},
    session: {type: 'object'}

  'level:shift-space-pressed': c.object {}

  'level:escape-pressed': c.object {}

  'level:enable-controls': c.object {},
    controls: c.array {},
      c.shortString()

  'level:disable-controls': c.object {},
    controls: c.array {},
      c.shortString()


  'level:set-letterbox': c.object {},
    on: {type: 'boolean'}

  'level:started': c.object {}

  'level:set-debug': c.object {required: ['debug']},
    debug: {type: 'boolean'}

  'level:restart': c.object {}

  'level:restarted': c.object {}

  'level:set-volume': c.object {required: ['volume']},
    volume: {type: 'number', minimum: 0, maximum: 1}

  'level:set-time': c.object {},
    time: {type: 'number', minimum: 0}
    ratio: {type: 'number', minimum: 0, maximum: 1}
    ratioOffset: {type: 'number'}
    frameOffset: {type: 'number'}
    scrubDuration: {type: 'number', minimum: 0}

  'level:select-sprite': c.object {},
    thangID: {type: ['string', 'null', 'undefined']}
    spellName: {type: ['string', 'null', 'undefined']}

  'level:set-playing': c.object {required: ['playing']},
    playing: {type: 'boolean'}

  'level:team-set': c.object {required: ['team']},
    team: c.shortString()

  'level:docs-shown': c.object {}

  'level:docs-hidden': c.object {}

  'level:flag-color-selected': c.object {},
    color:
      oneOf: [
        {type: 'null'}
        {type: 'string', enum: ['green', 'black', 'violet'], description: 'The flag color to place next, or omitted/null if deselected.'}
      ]
    pos: c.object {required: ['x', 'y']},
      x: {type: 'number'}
      y: {type: 'number'}

  'level:flag-updated': c.object {required: ['player', 'color', 'time', 'active']},
    player: {type: 'string'}
    team: {type: 'string'}
    color: {type: 'string', enum: ['green', 'black', 'violet']}
    time: {type: 'number', minimum: 0}
    active: {type: 'boolean'}
    pos: c.object {required: ['x', 'y']},
      x: {type: 'number'}
      y: {type: 'number'}
    source: {type: 'string', enum: ['click', 'code']}

  'level:next-game-pressed': c.object {}

  'level:loaded': c.object {required: ['level']},
    level: {type: 'object'}
    team: {type: ['string', 'null', 'undefined']}

  'level:session-loaded': c.object {required: ['level', 'session']},
    level: {type: 'object'}
    session: {type: 'object'}

  'level:loading-view-unveiling': c.object {}

  'level:loading-view-unveiled': c.object {required: ['view']},
    view: {type: 'object'}

  'playback:manually-scrubbed': c.object {required: ['ratio']},
    ratio: {type: 'number', minimum: 0, maximum: 1}

  'playback:stop-real-time-playback': c.object {}

  'playback:stop-cinematic-playback': c.object {}

  'playback:real-time-playback-started': c.object {}

  'playback:real-time-playback-ended': c.object {}

  'playback:cinematic-playback-started': c.object {}

  'playback:cinematic-playback-ended': c.object {}

  'playback:ended-changed': c.object {required: ['ended']},
    ended: {type: 'boolean'}

  'level:toggle-playing': c.object {}

  'level:toggle-grid': c.object {}

  'level:toggle-debug': c.object {}

  'level:toggle-pathfinding': c.object {}

  'level:scrub-forward': c.object {}

  'level:scrub-back': c.object {}

  'level:show-victory': c.object {required: ['showModal']},
    showModal: {type: 'boolean'}
    manual: { type: 'boolean' }
    capstoneInProgress: { type: 'boolean' }

  'level:highlight-dom': c.object {required: ['selector']},
    selector: {type: 'string'}
    delay: {type: ['number', 'null', 'undefined']}
    sides: {type: 'array', items: {'enum': ['left', 'right', 'top', 'bottom']}}
    offset: {type: 'object'}
    rotation: {type: 'number'}

  'level:end-highlight-dom': c.object {}

  'level:focus-dom': c.object {},
    selector: {type: 'string'}

  'level:lock-select': c.object {},
    lock: {type: ['boolean', 'array']}

  'level:suppress-selection-sounds': c.object {required: ['suppress']},
    suppress: {type: 'boolean'}

  'goal-manager:new-goal-states': c.object {required: ['goalStates', 'goals', 'overallStatus', 'timedOut']},
    goalStates:
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
    goals: c.array {},
      {type: 'object'}
    overallStatus:
      oneOf: [
        {type: 'null'}
        {type: 'string', enum: ['success', 'failure', 'incomplete']}
      ]
    timedOut: {type: 'boolean'}

  'level:hero-config-changed': c.object {}

  'level:hero-selection-updated': c.object {required: ['hero']},
    hero: {type: 'object'}

  'level:subscription-required': c.object {}

  'level:course-membership-required': c.object {}

  'level:contact-button-pressed': c.object {title: 'Contact Pressed', description: 'Dispatched when the contact button is pressed in a level.'}

  'level:surface-context-menu-pressed': c.object {required: ['posX', 'posY', 'wopX', 'wopY']},
    posX: {type: 'number'}
    posY: {type: 'number'}
    wopX: {type: 'number'}
    wopY: {type: 'number'}

  'level:surface-context-menu-hide': c.object {}

  'level:license-required': c.object {}

  'level:open-items-modal': c.object {}

  'level:scores-updated': c.object {},
    scores: c.array {},
      c.object {required: ['type', 'score']},
        type: c.shortString()
        score: {type: 'number'}

  'level:top-scores-updated': c.object {},
    scores: c.array {},
      c.object {required: ['type', 'score']},
        type: c.shortString()
        score: {type: 'number'}
        date: c.date()
