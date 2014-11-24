c = require 'schemas/schemas'

spriteMouseEventSchema = c.object {required: ['sprite', 'thang', 'originalEvent', 'canvas']},
  sprite: {type: 'object'}
  thang: {type: 'object'}
  originalEvent: {type: 'object'}
  canvas: {type: 'object'}

module.exports =  # /app/lib/surface
  'camera:dragged': c.object {}

  'camera:zoom-in': c.object {}

  'camera:zoom-out': c.object {}

  'camera:zoom-to': c.object {required: ['pos']},
    pos: c.object {required: ['x', 'y']},
      x: {type: 'number'}
      y: {type: 'number'}
    duration: {type: 'number', minimum: 0}

  'camera:zoom-updated': c.object {required: ['camera', 'zoom', 'surfaceViewport']},
    camera: {type: 'object'}
    zoom: {type: 'number', minimum: 0, exclusiveMinimum: true}
    surfaceViewport: {type: 'object'}
    minZoom: {type: 'number', minimum: 0, exclusiveMinimum: true}

  'camera:set-camera': c.object {},
    pos: c.object {required: ['x', 'y']},
      x: {type: 'number'}
      y: {type: 'number'}
    thangID: {type: 'string'}
    zoom: {type: 'number'}
    duration: {type: 'number', minimum: 0}
    bounds: c.array {maxItems: 2, minItems: 2},
      c.object {required: ['x', 'y']},
        x: {type: 'number'}
        y: {type: 'number'}

  'sprite:speech-updated': c.object {required: ['sprite', 'thang']},
    sprite: {type: 'object'}
    thang: {type: ['object', 'null']}
    blurb: {type: ['string', 'null', 'undefined']}
    message: {type: 'string'}
    mood: {type: 'string'}
    responses: {type: ['array', 'null', 'undefined']}
    spriteID: {type: 'string'}
    sound: {type: ['null', 'undefined', 'object']}

  'level:sprite-dialogue': c.object {required: ['spriteID', 'message']},
    blurb: {type: ['string', 'null', 'undefined']}
    message: {type: 'string'}
    mood: {type: 'string'}
    responses: {type: ['array', 'null', 'undefined']}
    spriteID: {type: 'string'}
    sound: {type: ['null', 'undefined', 'object']}

  'sprite:dialogue-sound-completed': c.object {}

  'level:sprite-clear-dialogue': c.object {}

  'surface:gold-changed': c.object {required: ['team', 'gold']},
    team: {type: 'string'}
    gold: {type: 'number'}
    goldEarned: {type: 'number'}

  'surface:coordinate-selected': c.object {required: ['x', 'y']},
    x: {type: 'number'}
    y: {type: 'number'}
    z: {type: 'number'}

  'surface:coordinates-shown': c.object {}

  'sprite:loaded': c.object {},
    sprite: {type: 'object'}

  'surface:choose-point': c.object {required: ['point']},
    point: c.object {required: ['x', 'y']},
      x: {type: 'number'}
      y: {type: 'number'}
      z: {type: 'number'}

  'surface:choose-region': c.object {required: ['points']},
    points: c.array {minItems: 2, maxItems: 2},
      c.object {required: ['x', 'y']},
        x: {type: 'number'}
        y: {type: 'number'}
        z: {type: 'number'}

  'surface:new-thang-added': c.object {required: ['thang', 'sprite']},
    thang: {type: 'object'}
    sprite: {type: 'object'}

  'surface:sprite-selected': c.object {required: ['thang', 'sprite']},
    thang: {type: ['object', 'null', 'undefined']}
    sprite: {type: ['object', 'null', 'undefined']}
    spellName: {type: ['string', 'null', 'undefined']}
    originalEvent: {type: ['object', 'null', 'undefined']}
    worldPos: {type: ['object', 'null', 'undefined']}

  'sprite:thang-began-talking': c.object {},
    thang: {type: 'object'}

  'sprite:thang-finished-talking': c.object {},
    thang: {type: 'object'}

  'sprite:highlight-sprites': c.object {},
    thangIDs: c.array {}, {type: 'string'}
    delay: {type: ['number', 'null', 'undefined']}

  'sprite:move': c.object {required: ['spriteID', 'pos']},
    spriteID: {type: 'string'}
    pos: c.object {required: ['x', 'y']},
      x: {type: 'number'}
      y: {type: 'number'}
      z: {type: 'number'}
    duration: {type: 'number', minimum: 0}

  'sprite:mouse-down': spriteMouseEventSchema
  'sprite:clicked': spriteMouseEventSchema
  'sprite:double-clicked': spriteMouseEventSchema
  'sprite:dragged': spriteMouseEventSchema
  'sprite:mouse-up': spriteMouseEventSchema

  'surface:frame-changed': c.object {required: ['frame', 'world', 'progress']},
    frame: {type: 'number', minimum: 0}
    world: {type: 'object'}
    progress: {type: 'number', minimum: 0, maximum: 1}
    selectedThang: {type: ['object', 'null', 'undefined']}

  'surface:playback-ended': c.object {}

  'surface:playback-restarted': c.object {}

  'surface:mouse-moved': c.object {required: ['x', 'y']},
    x: {type: 'number'}
    y: {type: 'number'}

  'surface:stage-mouse-down': c.object {required: ['onBackground', 'x', 'y', 'originalEvent']},
    onBackground: {type: 'boolean'}
    x: {type: 'number'}
    y: {type: 'number'}
    originalEvent: {type: 'object'}
    worldPos: {type: ['object', 'null', 'undefined']}

  'surface:stage-mouse-up': c.object {required: ['onBackground', 'originalEvent']},
    onBackground: {type: 'boolean'}
    x: {type: ['number', 'undefined']}
    y: {type: ['number', 'undefined']}
    originalEvent: {type: 'object'}

  'surface:mouse-scrolled': c.object {required: ['deltaX', 'deltaY', 'canvas']},
    deltaX: {type: 'number'}
    deltaY: {type: 'number'}
    screenPos: c.object {required: ['x', 'y']},
      x: {type: 'number'}
      y: {type: 'number'}
    canvas: {type: 'object'}

  'surface:ticked': c.object {required: ['dt']},
    dt: {type: 'number'}

  'surface:mouse-over': c.object {}

  'surface:mouse-out': c.object {}

  'sprite:echo-all-wizard-sprites': c.object {required: ['payload']},
    payload: c.array {}, {type: 'object'}

  'self-wizard:created': c.object {required: ['sprite']},
    sprite: {type: 'object'}

  'self-wizard:target-changed': c.object {required: ['sprite']},
    sprite: {type: 'object'}

  'surface:flag-appeared': c.object {required: ['sprite']},
    sprite: {type: 'object'}

  'surface:remove-selected-flag': c.object {}

  'surface:remove-flag': c.object {required: ['color']},
    color: {type: 'string'}
