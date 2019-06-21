c = require './../schemas'
LevelSchema = require './level'

CampaignSchema = c.object
  default:
    type: 'hero'
c.extendNamedProperties CampaignSchema  # name first

_.extend CampaignSchema.properties, {
  i18n: {type: 'object', title: 'i18n', format: 'i18n', props: ['name', 'fullName', 'description']}
  fullName: { type: 'string', title: 'Full Name', description: 'Ex.: "Kithgard Dungeon"' }
  description: { type: 'string', format: 'string', description: 'How long it takes and what players learn.' }
  type: c.shortString(title: 'Type', description: 'What kind of campaign this is.', 'enum': ['hero', 'course','hidden', 'hoc'])

  ambientSound: c.object {},
    mp3: { type: 'string', format: 'sound-file' }
    ogg: { type: 'string', format: 'sound-file' }

  backgroundImage: c.array {}, {
    type: 'object'
    additionalProperties: false
    properties: {
      image: { type: 'string', format: 'image-file' }
      width: { type: 'number' }
    }
  }
  backgroundColor: { type: 'string' }
  backgroundColorTransparent: { type: 'string' }

  adjacentCampaigns: { type: 'object', format: 'campaigns', additionalProperties: {
    title: 'Campaign'
    type: 'object'
    format: 'campaign'
    properties: {
      #- denormalized from other Campaigns, either updated automatically or fetched dynamically
      id: { type: 'string', format: 'hidden' }
      name: { type: 'string', format: 'hidden' }
      description: { type: 'string', format: 'hidden' }
      i18n: { type: 'object', format: 'hidden' }
      slug: { type: 'string', format: 'hidden' }

      #- normal properties
      position: c.point2d()
      rotation: { type: 'number', format: 'degrees' }
      color: { type: 'string' }
      showIfUnlocked:
        oneOf: [
          { type: 'string', links: [{rel: 'db', href: '/db/level/{($)}/version'}], format: 'latest-version-original-reference' }
          {
            type: 'array',
            items: { type: 'string', links: [{rel: 'db', href: '/db/level/{($)}/version'}], format: 'latest-version-original-reference' }
          }
        ]
    }
  }}
  levelsUpdated: c.date()

  levels: { type: 'object', format: 'levels', additionalProperties: {
    title: 'Level'
    type: 'object'
    format: 'level'
    additionalProperties: false

    # key is the original property
    properties: {
      #- denormalized from Achievements
      rewards: { format: 'rewards', type: 'array', items: {
        type: 'object'
        additionalProperties: false
        properties:
          achievement: { type: 'string', links: [{rel: 'db', href: '/db/achievement/{{$}}'}], format: 'achievement' }
          item: { type: 'string', links: [{rel: 'db', href: '/db/thang.type/{($)}/version'}], format: 'latest-version-original-reference' }
          hero: { type: 'string', links: [{rel: 'db', href: '/db/thang.type/{($)}/version'}], format: 'latest-version-original-reference' }
          level: { type: 'string', links: [{rel: 'db', href: '/db/level/{($)}/version'}], format: 'latest-version-original-reference' }
          type: { enum: ['heroes', 'items', 'levels'] }
      }}

      #- normal properties
      position: c.point2d()

      # properties relevant for ozaria campaigns
      nextLevels: {
        type: 'object'
        description: 'object containing next levels original id and their details'
        format: 'levels' # key is level original id
        additionalProperties: {
          type: 'object'
          format: 'nextLevel'
          properties: {
            nextLevelStage: {type: 'number', title: 'Next Level Stage', description: 'Which capstone stage is unlocked'}
            conditions: c.object({}, {
              afterCapstoneStage: {type: 'number', title: 'After Capstone Stage', description: 'What capstone stage needs to be completed to unlock this next level'}
            })
          }
        }
      }
      first: {type: 'boolean', description: 'Is it the first level in the campaign', default: true }

      #- denormalized properties from Levels are cloned below
    }

  }}
}

CampaignSchema.denormalizedLevelProperties = [
  'name'
  'description'
  'i18n'
  'requiresSubscription'
  'replayable'
  'type'
  'kind'
  'slug'
  'original'
  'adventurer'
  'assessment'
  'assessmentPlacement'
  'practice'
  'practiceThresholdMinutes'
  'primerLanguage'
  'shareable'
  'adminOnly'
  'disableSpaces'
  'hidesSubmitUntilRun'
  'hidesPlayButton'
  'hidesRunShortcut'
  'hidesHUD'
  'hidesSay'
  'hidesCodeToolbar'
  'hidesRealTimePlayback'
  'backspaceThrottle'
  'lockDefaultCode'
  'moveRightLoopSnippet'
  'realTimeSpeedFactor'
  'autocompleteFontSizePx'
  'requiredGear'
  'restrictedGear'
  'requiredProperties'
  'restrictedProperties'
  'recommendedHealth'
  'maximumHealth'
  'concepts'
  'primaryConcepts'
  'picoCTFProblem'
  'campaign'
  'campaignIndex'
  'scoreTypes'
  'isPlayedInStages'
  'ozariaType'
  'introContent'
]
hiddenLevelProperties = ['name', 'description', 'i18n', 'replayable', 'slug', 'original', 'primerLanguage', 'shareable', 'concepts', 'scoreTypes']
for prop in CampaignSchema.denormalizedLevelProperties
  CampaignSchema.properties.levels.additionalProperties.properties[prop] = _.cloneDeep(LevelSchema.properties[prop])
for hiddenProp in hiddenLevelProperties
  CampaignSchema.properties.levels.additionalProperties.properties[hiddenProp].format = 'hidden'

c.extendBasicProperties CampaignSchema, 'campaign'
c.extendTranslationCoverageProperties CampaignSchema
c.extendPatchableProperties CampaignSchema

module.exports = CampaignSchema
