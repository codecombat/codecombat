const c = require('./../schemas')
const LevelSchema = require('./level')
const colors = require('../../core/colors')

// Custom marker for one campaign entry (level or scenario). The asset is the state: a state without
// its own image falls back to `default`; locked without `locked` is `default` with the map's locked look.
const MapIconSchema = c.object({
  title: 'Map Icon',
  description: 'Custom marker drawn instead of the default level marker on every map that shows this campaign.',
  required: ['default'],
}, {
  default: { type: 'string', format: 'image-file', title: 'Default', description: 'Not started, and any state without its own image.' },
  inProgress: { type: 'string', format: 'image-file', title: 'In Progress' },
  complete: { type: 'string', format: 'image-file', title: 'Complete' },
  locked: { type: 'string', format: 'image-file', title: 'Locked', description: 'Shown as-is when locked. Without it the default image gets the locked treatment.' },
  scale: { type: 'number', title: 'Scale', description: 'Icon box relative to the base marker size of the map.', minimum: 0.25, maximum: 8, default: 1 },
  hoverEffect: { type: 'string', title: 'Hover Effect', enum: ['scale', 'glow', 'lift', 'none'], default: 'scale' },
  label: { type: 'string', title: 'Number Label', description: 'HackStack maps: the level number centred on the icon as on the default marker, in a bottom-right badge, or hidden.', enum: ['center', 'badge', 'none'], default: 'center' },
  labelColor: { type: 'string', format: 'color', title: 'Number Colour', description: 'HackStack maps: colour of the level number over this icon. Without it the number keeps its status colour (centre) or the badge text colour.' },
  labelScale: { type: 'number', title: 'Number Size', description: 'HackStack maps: height of the level number as a fraction of the icon box, so it grows with the scale. Empty keeps the default (0.34 centred, 0.22 badge).', minimum: 0, exclusiveMinimum: true, maximum: 1 },
})

// Draw order of everything placed on a map. Items are drawn in z order, equal z in array order, so decimals
// slot an item between two others. Defaults by kind: background 0, decorations 1, connection lines 2,
// level markers 3, labels 4; 5 lifts a decoration above the markers. Hover, tooltips and popups stay on top.
const MapZSchema = { type: 'number', title: 'Z', description: 'Draw order: 0 background, 1 decorations, 2 connections, 3 level markers, 4 labels, 5 above the markers. Decimals allowed; equal z draws in array order.', minimum: 0, maximum: 10 }

// Position relative to a decoration: its centre plus an offset in percent of that decoration's width, so
// moving or resizing the decoration carries everything anchored to it.
const MapAnchorSchema = c.object({ title: 'Anchor', description: 'Place this relative to a decoration: its centre plus the offset, in percent of the decoration width (x right, y up).', required: ['id'] }, {
  id: { type: 'string', title: 'Decoration id' },
  offset: c.point2d({ title: 'Offset', description: 'Percent of the anchor decoration width; x right, y up.' }),
})

const MapDecorationSchema = c.object({ title: 'Map Decoration', description: 'An image placed over the map, behind the level markers unless z says otherwise. Never clickable.', required: ['id', 'image', 'position'] }, {
  id: { type: 'string', title: 'Id', description: 'Unique on this campaign; anchors point at it.' },
  image: { type: 'string', format: 'image-file', title: 'Image', description: 'PNG or webp with alpha.' },
  position: c.point2d({ title: 'Position', description: 'Centre of the image, percent of the map, bottom-left origin.' }),
  width: { type: 'number', title: 'Width', description: 'Fraction of the map width; the height follows the image.', minimum: 0.01, maximum: 1, default: 0.1 },
  z: MapZSchema,
  rotation: { type: 'number', title: 'Rotation', description: 'Degrees, clockwise.', default: 0 },
  opacity: { type: 'number', title: 'Opacity', minimum: 0, maximum: 1, default: 1 },
  anchor: MapAnchorSchema,
  showIf: c.object({ title: 'Show if', description: 'Only drawn once this level is complete.', required: ['level'] }, {
    level: { type: 'string', title: 'Level', description: 'Level original id (Classic) or scenario original id (HackStack).' },
    status: { type: 'string', title: 'Status', enum: ['complete'], default: 'complete' },
  }),
})

// Text placed over the map: a chain name beside its planet, a hint on a module map. The plank sizes itself
// from the text so any translation fits; a custom plank is a 9-slice, so its caps keep their pixels while
// the middle stretches with the text.
const MapLabelSchema = c.object({ title: 'Map Label', description: 'Text placed over the map, above the markers unless z says otherwise. Never clickable.', required: ['id', 'text', 'position'] }, {
  id: { type: 'string', title: 'Id', description: 'Unique on this campaign.' },
  text: { type: 'string', title: 'Text', format: 'long-string', description: 'A line break starts a new line on the map. A label never wraps on its own.' },
  i18n: { type: 'object', format: 'i18n', props: ['text'], title: 'i18n', description: 'Translations of the text, line breaks included.' },
  position: c.point2d({ title: 'Position', description: 'Centre of the label, percent of the map, bottom-left origin.' }),
  z: MapZSchema,
  anchor: MapAnchorSchema,
  scale: { type: 'number', title: 'Scale', description: 'Relative to the base plank size of the map (the side-scroller plank at 1).', minimum: 0.25, maximum: 4, default: 1 },
  style: { type: 'string', title: 'Style', description: 'plank: the dark name plank with an accent border; chip: a small accent pill; none: text only.', enum: ['plank', 'chip', 'none'], default: 'plank' },
  accent: { type: 'string', format: 'color', title: 'Accent', description: 'Border colour of the plank, fill of the chip. Without it a neutral map grey; never a level status colour.' },
  plankImage: c.object({ title: 'Plank Image', description: 'Custom plank as a 9-slice: the caps keep their pixels, the middle stretches with the text.', required: ['image', 'slice'] }, {
    image: { type: 'string', format: 'image-file', title: 'Image' },
    slice: c.array({ title: 'Slice', description: 'Cap sizes in image pixels: top, right, bottom, left.', minItems: 4, maxItems: 4 }, { type: 'number', minimum: 0 }),
    padding: c.array({ title: 'Padding', description: 'Text inset inside the caps, in image pixels: horizontal, vertical.', minItems: 2, maxItems: 2 }, { type: 'number', minimum: 0 }),
  }),
})

const CampaignSchema = c.object({
  default: {
    type: 'hero',
  },
})
c.extendNamedProperties(CampaignSchema) // name first

_.extend(CampaignSchema.properties, {
  i18n: { type: 'object', title: 'i18n', format: 'i18n', props: ['name', 'fullName', 'description'] },
  fullName: { type: 'string', title: 'Full Name', description: 'Ex.: "Kithgard Dungeon"' },
  description: { type: 'string', format: 'string', description: 'How long it takes and what players learn.' },
  type: c.shortString({ title: 'Type', description: 'What kind of campaign this is.', enum: ['hero', 'course', 'hidden', 'hoc', 'hackstack', 'junior'] }),

  ambientSound: c.object({}, {
    mp3: { type: 'string', format: 'sound-file' },
    ogg: { type: 'string', format: 'sound-file' },
  }),

  backgroundImage: c.array({}, {
    type: 'object',
    additionalProperties: false,
    properties: {
      image: { type: 'string', format: 'image-file' },
      width: { type: 'number' }, // - not required for ozaria campaigns
      campaignPage: { type: 'number', title: 'Campaign page number', description: 'Give the page number if there are multiple pages in the campaign' }, // Oz-only,
    },
  }),
  backgroundColor: { type: 'string' },
  backgroundColorTransparent: { type: 'string' },

  adjacentCampaigns: {
    type: 'object',
    format: 'campaigns',
    additionalProperties: {
      title: 'Campaign',
      type: 'object',
      format: 'campaign',
      properties: {
      // - denormalized from other Campaigns, either updated automatically or fetched dynamically
        id: { type: 'string', format: 'hidden' },
        name: { type: 'string', format: 'hidden' },
        description: { type: 'string', format: 'hidden' },
        i18n: { type: 'object', format: 'hidden' },
        slug: { type: 'string', format: 'hidden' },

        // - normal properties
        position: c.point2d(),
        rotation: { type: 'number', format: 'degrees' },
        color: { type: 'string' },
        showIfUnlocked: {
          oneOf: [
            { type: 'string', links: [{ rel: 'db', href: '/db/level/{($)}/version' }], format: 'latest-version-original-reference' },
            {
              type: 'array',
              items: { type: 'string', links: [{ rel: 'db', href: '/db/level/{($)}/version' }], format: 'latest-version-original-reference' },
            },
          ],
        },
      },
    },
  },
  isOzaria: { type: 'boolean', description: 'Is this an ozaria campaign', default: false }, // TODO: migrate to using `product` instead
  isGalaxy: { type: 'boolean', description: 'Is this campaign the part of the Galaxy Interface', default: false },
  product: c.singleProduct,
  levelsUpdated: c.date(),

  levels: {
    type: 'object',
    format: 'levels',
    additionalProperties: {
      title: 'Level',
      type: 'object',
      format: 'level',
      additionalProperties: false,

      // key is the original property
      properties: {
      // - denormalized from Achievements
        rewards: {
          format: 'rewards',
          type: 'array',
          items: {
            type: 'object',
            additionalProperties: false,
            properties: {
              achievement: { type: 'string', links: [{ rel: 'db', href: '/db/achievement/{{$}}' }], format: 'achievement' },
              item: { type: 'string', links: [{ rel: 'db', href: '/db/thang.type/{($)}/version' }], format: 'latest-version-original-reference' },
              hero: { type: 'string', links: [{ rel: 'db', href: '/db/thang.type/{($)}/version' }], format: 'latest-version-original-reference' },
              level: { type: 'string', links: [{ rel: 'db', href: '/db/level/{($)}/version' }], format: 'latest-version-original-reference' },
              type: { enum: ['heroes', 'items', 'levels'] },
            },
          },
        },

        // - normal properties
        position: c.point2d(),
        mapIcon: MapIconSchema,
        z: MapZSchema,
        anchor: MapAnchorSchema,

        // properties relevant for ozaria campaigns
        nextLevels: {
          type: 'object',
          description: 'object containing next levels original id and their details',
          format: 'levels', // key is level original id
          additionalProperties: {
            type: 'object',
            format: 'nextLevel',
            properties: {
              nextLevelStage: { type: 'number', title: 'Next Level Stage', description: 'Which capstone stage is unlocked' },
              conditions: c.object({}, {
                afterCapstoneStage: { type: 'number', title: 'After Capstone Stage', description: 'What capstone stage needs to be completed to unlock this next level' },
              }),
            },
          },
        },
        first: { type: 'boolean', description: 'Is it the first level in the campaign', default: true },
        campaignPage: { type: 'number', title: 'Campaign page number', description: 'Give the page number if there are multiple pages in the campaign' },
        releasePhase: { enum: ['beta', 'internalRelease', 'released'], title: 'Release status', description: 'Release status of the level, determining who sees it.', default: 'internalRelease' },
        moduleNum: { type: 'number', title: 'Module number', default: 1 },
      // - denormalized properties from Levels are cloned below
      },

    },
  },
  scenarios: {
    type: 'array',
    title: 'AI Scenarios',
    items: {
      type: 'object',
      properties: {
        // scenario original
        scenario: c.stringID({ title: 'AI Scenario Original', format: 'scenario', links: [{ rel: 'db', href: '/db/ai_scenario/{{$}}/version', model: 'AIScenario' }] }),
        moduleNum: { type: 'number', title: 'Module number', default: 5 },
        position: c.point2d(),
        mapIcon: MapIconSchema,
        z: MapZSchema,
        anchor: MapAnchorSchema,
        displayName: { type: 'string', title: 'Display Name' },
        firstInSequence: { type: 'boolean', title: 'First in Sequence', default: false },
        connections: {
          type: 'array',
          title: 'Connections',
          items: {
            type: 'object',
            properties: {
              toScenario: c.stringID({ title: 'AI Scenario Original', format: 'scenario', links: [{ rel: 'db', href: '/db/ai_scenario/{{$}}/version', model: 'AIScenario' }] }),
              connectionType: { type: 'string', title: 'Connection Type', enum: ['required', 'optional'], default: 'required' },
              curveSide: { type: 'string', title: 'Curve Side', enum: ['left', 'right'], default: 'left' },
              color: { type: 'string', title: 'Color', format: 'color' },
              opacity: { type: 'number', title: 'Opacity', format: 'range', minimum: 0, maximum: 1, default: 0.5 },
              invisible: { type: 'boolean', title: 'Invisible', default: false },
            },
          },
        },
      },
    },
  },
  isIsolatedCampaign: { type: 'boolean', description: 'Isolated campaign, can be accessed only by direct link and dont have "back" button', default: false },
  isSideScrollerCampaign: { type: 'boolean', description: 'Side scroller campaign view', default: false },
  mapDecorations: c.array({ title: 'Map Decorations', description: 'Images placed over the map: planets, rocks, comets. Drawn by every map that shows this campaign.' }, MapDecorationSchema),
  mapLabels: c.array({ title: 'Map Labels', description: 'Text planks placed over the map: chain names, hints. Drawn by every map that shows this campaign.' }, MapLabelSchema),
  parallaxBackgrounds: {
    type: 'array',
    title: 'Parallax Backgrounds',
    description: 'Parallax backgrounds for the campaign',
    items: {
      type: 'object',
      additionalProperties: false,
      properties: {
        image: { type: 'string', format: 'image-file' },
        width: { type: 'number' },
        speedFactor: { type: 'number', title: 'Speed Factor', default: 1 },
      },
    },
  },
  isPremiumOnly: { type: 'boolean', description: 'Does this campaign require a subscription to access?', default: false },
  modules: {
    type: 'array',
    title: 'Modules',
    description: 'If the campaign is used as a parent campaign, it can have modules that are used as child campaigns.',
    items: {
      type: 'object',
      properties: {
        campaign: c.stringID({ title: 'Campaign', format: 'campaignID', model: 'Campaign', links: [{ rel: 'db', href: '/db/campaign/{{$}}', model: 'Campaign' }] }),
        moduleNumber: { type: 'number', title: 'Module number', description: 'The number of the module if its defined in the related course.' },
        portalImage: { format: 'image-file', title: 'Portal Image', description: 'The image to use for the portal of the module on interface.' },
        imageSize: {
          type: 'number',
          title: 'Relative Image Size',
          description: 'The relative size of the image to use for the portal of the module on interface. 0.1 means 10% of the map width.',
          minimum: 0,
          maximum: 1,
          default: 0.1, // 10% of the map width
        },
        position: {
          type: 'object',
          title: 'Position',
          properties: {
            // can be row/col or x/y, if both are provided, row/col takes precedence
            row: { type: 'number', title: 'Row', description: 'The row of the module on the interface.' },
            column: { type: 'number', title: 'Column', description: 'The column of the module on the interface.' },
            x: { type: 'number', title: 'X', description: 'The x position of the module on the interface.' },
            y: { type: 'number', title: 'Y', description: 'The y position of the module on the interface.' },
          },
        },
        access: { type: 'string', enum: ['free', 'sales-call', 'paid'], title: 'Access', description: 'Whether this module is free, free with a sales call, or paid.' },
        levelToUnlock: { type: 'string', title: 'Level to Unlock', description: 'Level original that must be completed to unlock this module.', links: [{ rel: 'db', href: '/db/level/{($)}/version' }], format: 'level-original' },
      },
    },
  },
  miniGames: {
    type: 'array',
    title: 'Mini-Games',
    description: 'Latent Space tiles: which mini-games this campaign shows, where they sit, and how they unlock.',
    items: {
      type: 'object',
      title: 'Mini-Game Tile',
      properties: {
        miniGame: { type: 'string', title: 'Mini-Game', format: 'mini-game-original', description: 'The MiniGame original this tile plays.', links: [{ rel: 'db', href: '/db/mini_game/{{$}}/version', model: 'MiniGame' }] },
        // - denormalized from the referenced MiniGame on save; the route, the analytics
        //   `gameName` and the tile identity all key off this.
        slug: { type: 'string', format: 'hidden' },
        displayName: { type: 'string', title: 'Display Name', description: 'Tile label. Falls back to the mini-game name.' },
        icon: { type: 'string', format: 'image-file', title: 'Icon', description: 'The image to use for the tile on the interface.' },
        accentColor: { type: 'string', format: 'color', title: 'Accent Color', description: 'Glow behind the tile on the Latent Space map, e.g. #FF5A3C. Leave empty for a neutral glow.' },
        position: {
          type: 'object',
          title: 'Position',
          description: 'Position of the tile on the interface.',
          properties: {
            // same shape and precedence as modules[].position
            row: { type: 'number', title: 'Row', description: 'The row of the tile on the interface.' },
            column: { type: 'number', title: 'Column', description: 'The column of the tile on the interface.' },
            x: { type: 'number', title: 'X', description: 'The x position of the tile on the interface.' },
            y: { type: 'number', title: 'Y', description: 'The y position of the tile on the interface.' },
          },
        },
        ruleToUnlock: {
          type: 'array',
          title: 'Rule To Unlock',
          description: 'All rules must pass for the tile to unlock. Empty means always unlocked. The first unmet rule supplies the lock message and where its click leads, so order them the way a player should work through them.',
          items: {
            type: 'object',
            title: 'Rule',
            properties: {
              type: c.shortString({ title: 'Type', description: 'stars: earn stars. registered: be signed up.', enum: ['stars', 'registered'] }),
              campaign: c.shortString({ title: 'Send To Campaign', description: 'stars only: where clicking the locked tile sends the player to go earn stars, e.g. intro-to-ai. Stars count no matter which campaign they came from. Empty sends them to the galaxy map.' }),
              amount: { type: 'integer', title: 'Amount', description: 'stars only: how many stars are needed, across all campaigns.', minimum: 0 },
            },
          },
        },
      },
    },
  },
  parentCampaignSlug: { type: 'string', title: 'Parent Campaign Slug', description: 'The slug of the parent campaign.' },
  visualConnections: {
    type: 'array',
    title: 'Visual Connections',
    description: 'Visual connections between levels or just random points on the map',
    items: {
      type: 'object',
      properties: {
        fromPos: c.point2d({ description: 'The position of the from point', title: 'From Position' }),
        toPos: c.point2d({ description: 'The position of the to point', title: 'To Position' }),
        opacity: { type: 'number', title: 'Opacity', format: 'range', minimum: 0, maximum: 1, default: 0.5 },
        // Curvature factor for this visual connection. 0 means straight line,
        // positive/negative values bend the connection in opposite directions.
        curve: {
          type: 'number',
          title: 'Curve',
          description: 'Curvature factor; 0 is straight, positive/negative bend the line left/right',
          default: 0,
        },
        // Head decoration at the end of the connection.
        head: {
          type: 'string',
          title: 'Head',
          description: 'What to draw at the end of the connection (none or arrow)',
          enum: ['none', 'arrow'],
          default: 'none',
        },
        // Relative thickness multiplier for the connection stroke.
        thickness: {
          type: 'number',
          title: 'Thickness',
          description: 'Relative thickness of the connection line; 1 = 1% of map height, 2 = 2%, etc.',
          default: 1,
          minimum: 0,
        },
        color: { type: 'string', format: 'color', description: 'The color of the connection', default: colors.black },
        lockedColor: { type: 'string', format: 'color', description: 'The color of the connection when it is locked', default: colors.grey },
        completeColor: { type: 'string', format: 'color', description: 'The color of the connection when it is completed', default: colors.lightGold },
        activeColor: { type: 'string', format: 'color', description: 'The color of the connection when it is active', default: colors.red },
        unlockLevelOriginal: {
          type: 'string',
          title: 'Unlock Level Original',
          description: 'Level original ID that unlocks or enables this connection; used to determine when the connection becomes available.',
          links: [{ rel: 'db', href: '/db/level/{($)}/version' }],
          format: 'level-original',
        },
        completeLevelOriginal: {
          type: 'string',
          title: 'Complete Level Original',
          description: 'Level original ID that marks completion of this connection; used to determine when the connection is finished.',
          links: [{ rel: 'db', href: '/db/level/{($)}/version' }],
          format: 'level-original',
        },
      },
    },
  },
})

CampaignSchema.denormalizedLevelProperties = [
  'name',
  'description',
  'i18n',
  'requiresSubscription',
  'classroomSub',
  'requiresSignUp',
  'replayable',
  'type',
  'kind',
  'slug',
  'original',
  'adventurer',
  'assessment',
  'assessmentPlacement',
  'practice',
  'practiceThresholdMinutes',
  'primerLanguage',
  'shareable',
  'adminOnly',
  'releasePhase',
  'disableSpaces',
  'hidesSubmitUntilRun',
  'hidesPlayButton',
  'hidesRunShortcut',
  'hidesHUD',
  'hidesSay',
  'hidesCodeToolbar',
  'hidesRealTimePlayback',
  'backspaceThrottle',
  'lockDefaultCode',
  'moveRightLoopSnippet',
  'permissions',
  'realTimeSpeedFactor',
  'autocompleteFontSizePx',
  'requiredGear',
  'restrictedGear',
  'requiredProperties',
  'restrictedProperties',
  'recommendedHealth',
  'maximumHealth',
  'clampedProperties',
  'concepts',
  'primaryConcepts',
  'campaign',
  'campaignIndex',
  'scoreTypes',
  // Ozaria
  'isPlayedInStages',
  'ozariaType',
  'introContent',
  'displayName',
  'hackstackScenarioId',
  'returnAfterCompleteMap',
]
const hiddenLevelProperties = ['name', 'description', 'i18n', 'replayable', 'slug', 'original', 'primerLanguage', 'shareable', 'concepts', 'scoreTypes']

CampaignSchema.definitions = CampaignSchema.definitions || {}
CampaignSchema.definitions.classroomSub = _.cloneDeep(LevelSchema.definitions?.classroomSub)

for (const prop of CampaignSchema.denormalizedLevelProperties) {
  CampaignSchema.properties.levels.additionalProperties.properties[prop] = _.cloneDeep(LevelSchema.properties[prop])
}
for (const hiddenProp of hiddenLevelProperties) {
  CampaignSchema.properties.levels.additionalProperties.properties[hiddenProp].format = 'hidden'
}

// Denormalized properties for module campaigns stored directly on the parent campaign.
CampaignSchema.denormalizedModuleCampaignProperties = [
  'name',
  'fullName',
  'slug',
  'i18n',
  'description',
]
for (const prop of CampaignSchema.denormalizedModuleCampaignProperties) {
  if (CampaignSchema.properties[prop]) {
    CampaignSchema.properties.modules.items.properties[prop] = _.cloneDeep(CampaignSchema.properties[prop])
  }
}

c.extendBasicProperties(CampaignSchema, 'campaign')
c.extendTranslationCoverageProperties(CampaignSchema)
c.extendPatchableProperties(CampaignSchema)

module.exports = CampaignSchema
