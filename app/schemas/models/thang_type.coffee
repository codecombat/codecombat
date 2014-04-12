c = require './../schemas'
ThangComponentSchema = require './thang_component'

ThangTypeSchema = c.object()
c.extendNamedProperties ThangTypeSchema  # name first

ShapeObjectSchema = c.object { title: 'Shape' },
  fc: { type: 'string', title: 'Fill Color' }
  lf: { type: 'array', title: 'Linear Gradient Fill' }
  ls: { type: 'array', title: 'Linear Gradient Stroke' }
  p: { type: 'string', title: 'Path' }
  de: { type: 'array', title: 'Draw Ellipse' }
  sc: { type: 'string', title: 'Stroke Color' }
  ss: { type: 'array', title: 'Stroke Style' }
  t: c.array {}, { type: 'number', title: 'Transform' }
  m: { type: 'string', title: 'Mask' }

ContainerObjectSchema = c.object { format: 'container' },
  b: c.array { title: 'Bounds' }, { type: 'number' }
  c: c.array { title: 'Children' }, { anyOf: [
    { type: 'string', title: 'Shape Child' },
    c.object { title: 'Container Child' }
      gn: { type: 'string', title: 'Global Name' }
      t: c.array {}, { type: 'number' }
  ]}

RawAnimationObjectSchema = c.object {},
  bounds: c.array { title: 'Bounds' }, { type: 'number' }
  frameBounds: c.array { title: 'Frame Bounds' }, c.array { title: 'Bounds' }, { type: 'number' }
  shapes: c.array {},
    bn: { type: 'string', title: 'Block Name' }
    gn: { type: 'string', title: 'Global Name' }
    im : { type: 'boolean', title: 'Is Mask' }
    m: { type: 'string', title: 'Uses Mask' }
  containers: c.array {},
    bn: { type: 'string', title: 'Block Name' }
    gn: { type: 'string', title: 'Global Name' }
    t: c.array {}, { type: 'number' }
    o: { type: 'boolean', title: 'Starts Hidden (_off)'}
    al: { type: 'number', title: 'Alpha'}
  animations: c.array {},
    bn: { type: 'string', title: 'Block Name' }
    gn: { type: 'string', title: 'Global Name' }
    t: c.array {}, { type: 'number', title: 'Transform' }
    a: c.array { title: 'Arguments' }
  tweens: c.array {},
    c.array { title: 'Function Chain', },
      c.object { title: 'Function Call' },
        n: { type: 'string', title: 'Name' }
        a: c.array { title: 'Arguments' }
  graphics: c.array {},
    bn: { type: 'string', title: 'Block Name' }
    p: { type: 'string', title: 'Path' }

PositionsSchema = c.object { title: 'Positions', description: 'Customize position offsets.' },
  registration: c.point2d { title: 'Registration Point', description: "Action-specific registration point override." }
  torso: c.point2d { title: 'Torso Offset', description: "Action-specific torso offset override." }
  mouth: c.point2d { title: 'Mouth Offset', description: "Action-specific mouth offset override." }
  aboveHead: c.point2d { title: 'Above Head Offset', description: "Action-specific above-head offset override." }

ActionSchema = c.object {},
  animation: { type: 'string', description: 'Raw animation being sourced', format: 'raw-animation' }
  container: { type: 'string', description: 'Name of the container to show' }
  relatedActions: c.object { },
    begin: { $ref: '#/definitions/action' }
    end: { $ref: '#/definitions/action' }
    main: { $ref: '#/definitions/action' }
    fore: { $ref: '#/definitions/action' }
    back: { $ref: '#/definitions/action' }
    side: { $ref: '#/definitions/action' }

    "?0?011?11?11": { $ref: '#/definitions/action', title: "NW corner" }
    "?0?11011?11?": { $ref: '#/definitions/action', title: "NE corner, flipped" }
    "?0?111111111": { $ref: '#/definitions/action', title: "N face" }
    "?11011011?0?": { $ref: '#/definitions/action', title: "SW corner, top" }
    "11?11?110?0?": { $ref: '#/definitions/action', title: "SE corner, top, flipped" }
    "?11011?0????": { $ref: '#/definitions/action', title: "SW corner, bottom" }
    "11?110?0????": { $ref: '#/definitions/action', title: "SE corner, bottom, flipped" }
    "?11011?11?11": { $ref: '#/definitions/action', title: "W face" }
    "11?11011?11?": { $ref: '#/definitions/action', title: "E face, flipped" }
    "011111111111": { $ref: '#/definitions/action', title: "NW elbow" }
    "110111111111": { $ref: '#/definitions/action', title: "NE elbow, flipped" }
    "111111111?0?": { $ref: '#/definitions/action', title: "S face, top" }
    "111111?0????": { $ref: '#/definitions/action', title: "S face, bottom" }
    "111111111011": { $ref: '#/definitions/action', title: "SW elbow, top" }
    "111111111110": { $ref: '#/definitions/action', title: "SE elbow, top, flipped" }
    "111111011?11": { $ref: '#/definitions/action', title: "SW elbow, bottom" }
    "11111111011?": { $ref: '#/definitions/action', title: "SE elbow, bottom, flipped" }
    "111111111111": { $ref: '#/definitions/action', title: "Middle" }

  loops: { type: 'boolean' }
  speed: { type: 'number' }
  goesTo: { type: 'string', description: 'Action (animation?) to which we switch after this animation.' }
  frames: { type: 'string', pattern:'^[0-9,]+$', description: 'Manually way to specify frames.' }
  framerate: { type: 'number', description: 'Get this from the HTML output.' }
  positions: PositionsSchema
  scale: { title: 'Scale', type: 'number' }
  flipX: { title: "Flip X", type: 'boolean', description: "Flip this animation horizontally?" }
  flipY: { title: "Flip Y", type: 'boolean', description: "Flip this animation vertically?" }

SoundSchema = c.sound({delay: { type: 'number' }})

_.extend ThangTypeSchema.properties,
  raw: c.object {title: 'Raw Vector Data'},
    shapes: c.object {title: 'Shapes', additionalProperties: ShapeObjectSchema}
    containers: c.object {title: 'Containers', additionalProperties: ContainerObjectSchema}
    animations: c.object {title: 'Animations', additionalProperties: RawAnimationObjectSchema}
  kind: c.shortString { enum: ['Unit', 'Floor', 'Wall', 'Doodad', 'Misc', 'Mark'], default: 'Misc', title: 'Kind' }

  actions: c.object { title: 'Actions', additionalProperties: { $ref: '#/definitions/action' } }
  soundTriggers: c.object { title: "Sound Triggers", additionalProperties: c.array({}, { $ref: '#/definitions/sound' }) },
    say: c.object { format: 'slug-props', additionalProperties: { $ref: '#/definitions/sound' } },
      defaultSimlish: c.array({}, { $ref: '#/definitions/sound' })
      swearingSimlish: c.array({}, { $ref: '#/definitions/sound' })
  rotationType: { title: 'Rotation', type: 'string', enum: ['isometric', 'fixed']}
  matchWorldDimensions: { title: 'Match World Dimensions', type: 'boolean' }
  shadow: { title: 'Shadow Diameter', type: 'number', format: 'meters', description: "Shadow diameter in meters" }
  layerPriority:
    title: 'Layer Priority'
    type: 'integer'
    description: "Within its layer, sprites are sorted by layer priority, then y, then z."
  scale:
    title: 'Scale'
    type: 'number'
  positions: PositionsSchema
  colorGroups: c.object
    title: 'Color Groups'
    additionalProperties:
      type:'array'
      format: 'thang-color-group'
      items: {type:'string'}
  snap: c.object { title: "Snap", description: "In the level editor, snap positioning to these intervals.", required: ['x', 'y'] },
    x:
      title: "Snap X"
      type: 'number'
      description: "Snap to this many meters in the x-direction."
      default: 4
    y:
      title: "Snap Y"
      type: 'number'
      description: "Snap to this many meters in the y-direction."
      default: 4
  components: c.array {title: "Components", description: "Thangs are configured by changing the Components attached to them.", uniqueItems: true, format: 'thang-components-array'}, ThangComponentSchema  # TODO: uniqueness should be based on "original", not whole thing

ThangTypeSchema.definitions =
  action: ActionSchema
  sound: SoundSchema

c.extendBasicProperties ThangTypeSchema, 'thang.type'
c.extendSearchableProperties ThangTypeSchema
c.extendVersionedProperties ThangTypeSchema, 'thang.type'
c.extendPatchableProperties ThangTypeSchema

module.exports = ThangTypeSchema
