const c = require('./../schemas')
const ThangComponentSchema = require('./thang_component')

const ThangTypeSchema = c.object({ default: { kind: 'Misc' } })
c.extendNamedProperties(ThangTypeSchema) // name first

const ShapeObjectSchema = c.object({ title: 'Shape' }, {
  fc: { type: 'string', title: 'Fill Color' },
  lf: { type: 'array', title: 'Linear Gradient Fill' },
  rf: { type: 'array', title: 'Radial Gradient Fill' },
  ls: { type: 'array', title: 'Linear Gradient Stroke' },
  p: { type: 'string', title: 'Path' },
  de: { type: 'array', title: 'Draw Ellipse' },
  sc: { type: 'string', title: 'Stroke Color' },
  ss: { type: 'array', title: 'Stroke Style' },
  t: c.array({}, { type: 'number', title: 'Transform' }),
  m: { type: 'string', title: 'Mask' },
  bounds: c.array({ title: 'Bounds' }, { type: 'number' })
})

const ContainerObjectSchema = c.object({ format: 'container' }, {
  b: c.array({ title: 'Bounds' }, { type: 'number' }),
  c: c.array({ title: 'Children' }, {
    anyOf: [
      { type: 'string', title: 'Shape Child' },
      c.object({ title: 'Container Child' }), {
        gn: { type: 'string', title: 'Global Name' },
        t: c.array({}, { type: 'number' })
      }
    ]
  })
})

const RawAnimationObjectSchema = c.object({}, {
  bounds: c.array({ title: 'Bounds' }, { type: 'number' }),
  frameBounds: c.array({ title: 'Frame Bounds' }, c.array({ title: 'Bounds' }, { type: 'number' })),
  shapes: c.array({}, {
    bn: { type: 'string', title: 'Block Name' },
    gn: { type: 'string', title: 'Global Name' },
    im: { type: 'boolean', title: 'Is Mask' },
    m: { type: 'string', title: 'Uses Mask' }
  }),
  containers: c.array({}, {
    bn: { type: 'string', title: 'Block Name' },
    gn: { type: 'string', title: 'Global Name' },
    t: c.array({}, { type: 'number' }),
    o: { type: 'boolean', title: 'Starts Hidden (_off)' },
    al: { type: 'number', title: 'Alpha' }
  }),
  animations: c.array({}, {
    bn: { type: 'string', title: 'Block Name' },
    gn: { type: 'string', title: 'Global Name' },
    t: c.array({}, { type: 'number', title: 'Transform' }),
    a: c.array({ title: 'Arguments' }),
    off: { type: 'bolean', title: 'Starts Hidden (_off)' }
  }),
  tweens: c.array({},
    c.array({ title: 'Function Chain' },
      c.object({ title: 'Function Call' }, {
        n: { type: 'string', title: 'Name' },
        a: c.array({ title: 'Arguments' })
      }))),
  graphics: c.array({}, {
    bn: { type: 'string', title: 'Block Name' },
    p: { type: 'string', title: 'Path' }
  })
})

const PositionsSchema = c.object({ title: 'Positions', description: 'Customize position offsets.' }, {
  registration: c.point2d({ title: 'Registration Point', description: 'Action-specific registration point override.' }),
  torso: c.point2d({ title: 'Torso Offset', description: 'Action-specific torso offset override.' }),
  mouth: c.point2d({ title: 'Mouth Offset', description: 'Action-specific mouth offset override.' }),
  aboveHead: c.point2d({ title: 'Above Head Offset', description: 'Action-specific above-head offset override.' })
})

const ActionSchema = c.object({}, {
  animation: { type: 'string', description: 'Raw animation being sourced', format: 'raw-animation' },
  container: { type: 'string', description: 'Name of the container to show' },
  relatedActions: c.object({}, {
    begin: { $ref: '#/definitions/action' },
    end: { $ref: '#/definitions/action' },
    main: { $ref: '#/definitions/action' },
    fore: { $ref: '#/definitions/action' },
    back: { $ref: '#/definitions/action' },
    side: { $ref: '#/definitions/action' },

    '?0?011?11?11': { $ref: '#/definitions/action', title: 'NW corner' },
    '?0?11011?11?': { $ref: '#/definitions/action', title: 'NE corner, flipped' },
    '?0?111111111': { $ref: '#/definitions/action', title: 'N face' },
    '?11011011?0?': { $ref: '#/definitions/action', title: 'SW corner, top' },
    '11?11?110?0?': { $ref: '#/definitions/action', title: 'SE corner, top, flipped' },
    '?11011?0????': { $ref: '#/definitions/action', title: 'SW corner, bottom' },
    '11?110?0????': { $ref: '#/definitions/action', title: 'SE corner, bottom, flipped' },
    '?11011?11?11': { $ref: '#/definitions/action', title: 'W face' },
    '11?11011?11?': { $ref: '#/definitions/action', title: 'E face, flipped' },
    '011111111111': { $ref: '#/definitions/action', title: 'NW elbow' },
    110111111111: { $ref: '#/definitions/action', title: 'NE elbow, flipped' },
    '111111111?0?': { $ref: '#/definitions/action', title: 'S face, top' },
    '111111?0????': { $ref: '#/definitions/action', title: 'S face, bottom' },
    111111111011: { $ref: '#/definitions/action', title: 'SW elbow, top' },
    111111111110: { $ref: '#/definitions/action', title: 'SE elbow, top, flipped' },
    '111111011?11': { $ref: '#/definitions/action', title: 'SW elbow, bottom' },
    '11111111011?': { $ref: '#/definitions/action', title: 'SE elbow, bottom, flipped' },
    111111111111: { $ref: '#/definitions/action', title: 'Middle' },

    '000000000': { $ref: '#/definitions/action', title: '00 Full' },
    111111111: { $ref: '#/definitions/action', title: '01 Empty' },
    111111011: { $ref: '#/definitions/action', title: '02 SW corner' },
    111111110: { $ref: '#/definitions/action', title: '03 SE corner, flipped' },
    '011111111': { $ref: '#/definitions/action', title: '04 NW corner' },
    110111111: { $ref: '#/definitions/action', title: '05 NW corner, flipped' },
    111111010: { $ref: '#/definitions/action', title: '06 S double corner' },
    '010111111': { $ref: '#/definitions/action', title: '07 N double corner' },
    '011111011': { $ref: '#/definitions/action', title: '08 W double corner' },
    110111110: { $ref: '#/definitions/action', title: '09 E double corner, flipped' },
    110111011: { $ref: '#/definitions/action', title: '10 SW/NE double corner' },
    '011111110': { $ref: '#/definitions/action', title: '11 SE/NW double corner, flipped' },
    '010111011': { $ref: '#/definitions/action', title: '12 SW/NW/NE triple corner' },
    '010111110': { $ref: '#/definitions/action', title: '13 SE/NW/NE triple corner, flipped' },
    '011111010': { $ref: '#/definitions/action', title: '14 NW/SW/SE triple corner' },
    110111010: { $ref: '#/definitions/action', title: '15 NE/SW/SE triple corner, flipped' },
    '010111010': { $ref: '#/definitions/action', title: '16 Four corners' },
    111111000: { $ref: '#/definitions/action', title: '17 S edge' },
    '000111111': { $ref: '#/definitions/action', title: '18 N edge' },
    '011011011': { $ref: '#/definitions/action', title: '19 W edge' },
    110110110: { $ref: '#/definitions/action', title: '20 E edge, flipped' },
    '011111000': { $ref: '#/definitions/action', title: '21 NW corner, S edge' },
    110111000: { $ref: '#/definitions/action', title: '22 NE corner, S edge, flipped' },
    '000111011': { $ref: '#/definitions/action', title: '23 SW corner, N edge' },
    '000111110': { $ref: '#/definitions/action', title: '24 SE corner, N edge, flipped' },
    '011011010': { $ref: '#/definitions/action', title: '25 SE corner, W edge' },
    110110010: { $ref: '#/definitions/action', title: '26 SW corner, E edge, flipped' },
    '010011011': { $ref: '#/definitions/action', title: '27 NE corner, W edge' },
    '010110110': { $ref: '#/definitions/action', title: '28 NW corner, E edge, flipped' },
    '010111000': { $ref: '#/definitions/action', title: '29 N double corner, S edge' },
    '000111010': { $ref: '#/definitions/action', title: '30 S double corner, N edge' },
    '010011010': { $ref: '#/definitions/action', title: '31 E double corner, W edge' },
    '010110010': { $ref: '#/definitions/action', title: '32 W double corner, E edge, flipped' },
    '010010010': { $ref: '#/definitions/action', title: '33 W/E double edge' },
    '000111000': { $ref: '#/definitions/action', title: '34 N/S double edge' },
    '011011000': { $ref: '#/definitions/action', title: '35 W/S double edge' },
    110110000: { $ref: '#/definitions/action', title: '36 E/S double edge, flipped' },
    '000011011': { $ref: '#/definitions/action', title: '37 W/N double edge' },
    '000110110': { $ref: '#/definitions/action', title: '38 E/N double edge, flipped' },
    '010011000': { $ref: '#/definitions/action', title: '39 W/S double edge, NE corner' },
    '010110000': { $ref: '#/definitions/action', title: '40 E/S double edge, NW corner, flipped' },
    '000011010': { $ref: '#/definitions/action', title: '41 W/N double edge, SE corner' },
    '000110010': { $ref: '#/definitions/action', title: '42 E/N double edge, SW corner, flipped' },
    '010010000': { $ref: '#/definitions/action', title: '43 S/W/E triple edge' },
    '000010010': { $ref: '#/definitions/action', title: '44 N/W/E triple edge' },
    '000011000': { $ref: '#/definitions/action', title: '45 W/S/N triple edge' },
    '000110000': { $ref: '#/definitions/action', title: '46 E/S/N triple edge, flipped' },
    '000010000': { $ref: '#/definitions/action', title: '47 Hole' },
  }),

  loops: { type: 'boolean' },
  speed: { type: 'number' },
  goesTo: { type: 'string', description: 'Action (animation?) to which we switch after this animation.' },
  frames: { type: 'string', pattern: '^[0-9,]+$', description: 'Manually way to specify frames.' },
  framerate: { type: 'number', description: 'Get this from the HTML output.' },
  positions: PositionsSchema,
  scale: { title: 'Scale', type: 'number' },
  flipX: { title: 'Flip X', type: 'boolean', description: 'Flip this animation horizontally?' },
  flipY: { title: 'Flip Y', type: 'boolean', description: 'Flip this animation vertically?' }
})

const SoundSchema = c.sound({ delay: { type: 'number' } })

const RasterAtlasAnimationSchema = c.object({}, {
  movieClipName: { type: 'string', title: 'MovieClip name in JavaScript file' },
  textureAtlases: c.array({ title: 'Texture Atlas Images' },
    { type: 'string', format: 'image-file' }),
  movieClip: { type: 'string', title: 'MovieClip Javascript file', format: 'js-file' }
})

_.extend(ThangTypeSchema.properties, {
  raw: c.object({ title: 'Raw Vector Data', default: { shapes: {}, containers: {}, animations: {} } }, {
    shapes: c.object({ title: 'Shapes', additionalProperties: ShapeObjectSchema }),
    containers: c.object({ title: 'Containers', additionalProperties: ContainerObjectSchema }),
    animations: c.object({ title: 'Animations', additionalProperties: RawAnimationObjectSchema })
  }),
  kind: c.shortString({ enum: ['Unit', 'Floor', 'Wall', 'Doodad', 'Misc', 'Mark', 'Item', 'Hero', 'Missile', 'Junior', 'Junior Hero'], default: 'Misc', title: 'Kind' }),
  terrains: c.array({ title: 'Terrains', description: 'If specified, limits this ThangType to levels with matching terrains.', uniqueItems: true }, c.terrainString),
  gems: { type: 'integer', minimum: 0, title: 'Gem Cost', description: 'How many gems this item or hero costs.' },
  subscriber: { type: 'boolean', title: 'Subscriber (items only)', description: 'This item is for subscribers only.' },
  heroClass: { type: 'string', enum: ['Warrior', 'Ranger', 'Wizard'], title: 'Hero Class', description: 'What class this is (if a hero) or is restricted to (if an item). Leave undefined for most items.' },
  tier: { type: 'number', minimum: 0, title: 'Tier', description: 'What tier (fractional) this item or hero is in.' },
  actions: c.object({ title: 'Actions', additionalProperties: { $ref: '#/definitions/action' } }),
  soundTriggers: c.object({ title: 'Sound Triggers', additionalProperties: c.array({}, { $ref: '#/definitions/sound' }) }, {
    say: c.object({ format: 'slug-props', additionalProperties: { $ref: '#/definitions/sound' } }, {
      defaultSimlish: c.array({}, { $ref: '#/definitions/sound' }),
      swearingSimlish: c.array({}, { $ref: '#/definitions/sound' })
    }
    )
  }
  ),
  rotationType: { title: 'Rotation', type: 'string', enum: ['isometric', 'fixed', 'free'] },
  matchWorldDimensions: { title: 'Match World Dimensions', type: 'boolean' },
  shadow: { title: 'Shadow Diameter', type: 'number', format: 'meters', description: 'Shadow diameter in meters' },
  description: { type: 'string', format: 'markdown', title: 'Description' },
  layerPriority: {
    title: 'Layer Priority',
    type: 'integer',
    description: 'Within its layer, sprites are sorted by layer priority, then y, then z.'
  },
  scale: {
    title: 'Scale',
    type: 'number'
  },
  spriteType: { enum: ['singular', 'segmented', 'rasterAtlas'], title: 'Sprite Type' },
  positions: PositionsSchema,
  raster: { type: 'string', format: 'image-file', title: 'Raster Image' },
  rasterIcon: { type: 'string', format: 'image-file', title: 'Raster Image Icon' },
  containerIcon: { type: 'string' },
  poseImage: { type: 'string', format: 'image-file', title: 'Pose Image' },
  featureImages: c.object({ title: 'Hero Doll Images' }, {
    body: { type: 'string', format: 'image-file', title: 'Body' },
    head: { type: 'string', format: 'image-file', title: 'Head' },
    hair: { type: 'string', format: 'image-file', title: 'Hair' },
    thumb: { type: 'string', format: 'image-file', title: 'Thumb' },
    wizardHand: { type: 'string', format: 'image-file', title: 'Wizard Hand' }
  }),
  dollImages: c.object({ title: 'Paper Doll Images' }, {
    male: { type: 'string', format: 'image-file', title: 'Male' },
    female: { type: 'string', format: 'image-file', title: 'Female' },
    maleThumb: { type: 'string', format: 'image-file', title: 'Thumb (Male)' },
    femaleThumb: { type: 'string', format: 'image-file', title: 'Thumb (Female)' },
    maleRanger: { type: 'string', format: 'image-file', title: 'Glove (Male Ranger)' },
    maleRangerThumb: { type: 'string', format: 'image-file', title: 'Thumb (Male Ranger)' },
    femaleRanger: { type: 'string', format: 'image-file', title: 'Glove (Female Ranger)' },
    femaleRangerThumb: { type: 'string', format: 'image-file', title: 'Thumb (Female Ranger)' },
    maleBack: { type: 'string', format: 'image-file', title: 'Male Back' },
    femaleBack: { type: 'string', format: 'image-file', title: 'Female Back' },
    pet: { type: 'string', format: 'image-file', title: 'Pet' }
  }),
  colorGroups: c.object({
    title: 'Color Groups',
    additionalProperties: {
      type: 'array',
      format: 'thang-color-group',
      items: { type: 'string' }
    }
  }),
  snap: c.object({ title: 'Snap', description: 'In the level editor, snap positioning to these intervals.', required: ['x', 'y'], default: { x: 4, y: 4 } }, {
    x: {
      title: 'Snap X',
      type: 'number',
      description: 'Snap to this many meters in the x-direction.'
    },
    y: {
      title: 'Snap Y',
      type: 'number',
      description: 'Snap to this many meters in the y-direction.'
    }
  }
  ),
  components: c.array({ title: 'Components', description: 'Thangs are configured by changing the Components attached to them.', uniqueItems: true, format: 'thang-components-array' }, ThangComponentSchema), // TODO: uniqueness should be based on 'original', not whole thing
  i18n: { type: 'object', format: 'i18n', props: ['name', 'description', 'extendedName', 'shortName', 'unlockLevelName', 'soundTriggers'], description: 'Help translate this ThangType\'s name and description.' },
  extendedName: { type: 'string', title: 'Extended Hero Name', description: 'The long form of the hero\'s name. Ex.: "Captain Anya Weston".' },
  shortName: { type: 'string', title: 'Short Hero Name', description: 'The short form of the hero\'s name. Ex.: "Anya".' },
  unlockLevelName: { type: 'string', title: 'Unlock Level Name', description: 'The name of the level in which the hero is unlocked.' },
  tasks: c.array({ title: 'Tasks', description: 'Tasks to be completed for this ThangType.' }, c.task),
  preLoadActions: c.array({ title: 'Preload Actions', description: 'List of actions that should be rasterized immediately' }, c.shortString({ minLength: 1 })),
  prerenderedSpriteSheetData: c.array({ title: 'Prerendered SpriteSheet Data' },
    c.object({ title: 'SpriteSheet' }, {
      actionNames: { type: 'array' },
      animations: {
        type: 'object',
        description: 'Third EaselJS SpriteSheet animations format',
        additionalProperties: {
          description: 'EaselJS animation',
          type: 'object',
          properties: {
            frames: { type: 'array' },
            next: { type: ['string', 'null'] },
            speed: { type: 'number' }
          }
        }
      },
      colorConfig: c.object({ additionalProperties: c.colorConfig() }),
      colorLabel: { enum: ['red', 'green', 'blue'] },
      frames: {
        type: 'array',
        description: 'Second EaselJS SpriteSheet frames format',
        items: {
          type: 'array',
          items: [
            { type: 'number', title: 'x' },
            { type: 'number', title: 'y' },
            { type: 'number', title: 'width' },
            { type: 'number', title: 'height' },
            { type: 'number', title: 'imageIndex' },
            { type: 'number', title: 'regX' },
            { type: 'number', title: 'regY' }
          ]
        }
      },
      image: { type: 'string', format: 'image-file' },
      resolutionFactor: {
        type: 'number'
      },
      spriteType: { enum: ['singular', 'segmented'], title: 'Sprite Type' }
    })),
  // rasterAtlasAnimations stores raster atlas data for different animation names as the key
  rasterAtlasAnimations: {
    title: 'Raster Atlas Animation Data',
    type: 'object',
    additionalProperties: { $ref: '#/definitions/rasterAtlasAnimationData' }
  },
  restricted: { type: 'string', title: 'Restricted', description: 'If set, this ThangType will only be accessible by admins and whoever it is restricted to.' },
  releasePhase: { enum: ['beta', 'released'], description: "How far along the ThangType's development is, determining who sees it." },
  gender: { enum: ['female', 'male'], type: 'string', title: 'Hero Gender', description: 'Affects which paper doll image set and language pronouns to use.' },
  ozaria: { type: 'boolean', description: 'Marks this thang as an Ozaria only type. Used to prevent Ozaria hero\'s from appearing in CodeCombat hero selector.' },
  archived: { type: 'integer', description: 'Marks this thang to be hidden from searches and lookups. Number is milliseconds since 1 January 1970 UTC, when it was marked as hidden.' }
})

ThangTypeSchema.required = []

ThangTypeSchema.default =
  { raw: {} }

ThangTypeSchema.definitions = {
  action: ActionSchema,
  sound: SoundSchema,
  rasterAtlasAnimationData: RasterAtlasAnimationSchema
}

c.extendBasicProperties(ThangTypeSchema, 'thang.type')
c.extendSearchableProperties(ThangTypeSchema)
c.extendVersionedProperties(ThangTypeSchema, 'thang.type')
c.extendPatchableProperties(ThangTypeSchema)
c.extendTranslationCoverageProperties(ThangTypeSchema)

module.exports = ThangTypeSchema
