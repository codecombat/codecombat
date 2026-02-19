const c = require('./../schemas')
const LevelSchema = require('./level')

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
        color: { type: 'string', format: 'color', description: 'The color of the connection' },
        opacity: { type: 'number', title: 'Opacity', format: 'range', minimum: 0, maximum: 1, default: 0.5 },
        // Curvature factor for this visual connection. 0 means straight line,
        // positive/negative values bend the connection in opposite directions.
        curve: {
          type: 'number',
          title: 'Curve',
          description: 'Curvature factor; 0 is straight, positive/negative bend the line left/right',
          default: 0,
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
]
const hiddenLevelProperties = ['name', 'description', 'i18n', 'replayable', 'slug', 'original', 'primerLanguage', 'shareable', 'concepts', 'scoreTypes']
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
