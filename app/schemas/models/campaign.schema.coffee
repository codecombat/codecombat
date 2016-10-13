c = require './../schemas'

CampaignSchema = c.object
  default:
    type: 'hero'
c.extendNamedProperties CampaignSchema  # name first

_.extend CampaignSchema.properties, {
  i18n: {type: 'object', title: 'i18n', format: 'i18n', props: ['name', 'fullName', 'description']}
  fullName: { type: 'string', title: 'Full Name', description: 'Ex.: "Kithgard Dungeon"' }
  description: { type: 'string', format: 'string', description: 'How long it takes and what players learn.' }
  type: c.shortString(title: 'Type', description: 'What kind of campaign this is.', 'enum': ['hero', 'course','hidden'])

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
      #- denormalized from Level
      name: { type: 'string', format: 'hidden' }
      description: { type: 'string', format: 'hidden' }
      i18n: { type: 'object', format: 'hidden' }
      requiresSubscription: { type: 'boolean' }
      replayable: { type: 'boolean', format: 'hidden' }
      type: {'enum': ['ladder', 'ladder-tutorial', 'hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev', 'web-dev']}
      slug: { type: 'string', format: 'hidden' }
      original: { type: 'string', format: 'hidden' }
      adventurer: { type: 'boolean' }
      practice: { type: 'boolean' }
      practiceThresholdMinutes: { type: 'number' }
      primerLanguage: { type: 'string', enum: ['javascript', 'python'], format: 'hidden' }
      shareable: { title: 'Shareable', type: ['string', 'boolean'], enum: [false, true, 'project'], description: 'Whether the level is not shareable, shareable, or a sharing-encouraged project level.', format: 'hidden' }
      adminOnly: { type: 'boolean' }
      disableSpaces: { type: ['boolean','number'] }
      hidesSubmitUntilRun: { type: 'boolean' }
      hidesPlayButton: { type: 'boolean' }
      hidesRunShortcut: { type: 'boolean' }
      hidesHUD: { type: 'boolean' }
      hidesSay: { type: 'boolean' }
      hidesCodeToolbar: { type: 'boolean' }
      hidesRealTimePlayback: { type: 'boolean' }
      backspaceThrottle: { type: 'boolean' }
      lockDefaultCode: { type: ['boolean','number'] }
      moveRightLoopSnippet: { type: 'boolean' }
      realTimeSpeedFactor: { type: 'number' }
      autocompleteFontSizePx: { type: 'number' }

      requiredGear: { type: 'object', additionalProperties: {
        type: 'array'
        items: { type: 'string', links: [{rel: 'db', href: '/db/thang.type/{($)}/version'}], format: 'latest-version-original-reference' }
      }}
      restrictedGear: { type: 'object', additionalProperties: {
        type: 'array'
        items: { type: 'string', links: [{rel: 'db', href: '/db/thang.type/{($)}/version'}], format: 'latest-version-original-reference' }
      }}
      allowedHeroes: { type: 'array', items: {
        type: 'string', links: [{rel: 'db', href: '/db/thang.type/{($)}/version'}], format: 'latest-version-original-reference'
      }}

      concepts: c.array {title: 'Programming Concepts', description: 'Which programming concepts this level covers.', format: 'hidden'}, c.concept
      picoCTFProblem: { type: 'string', description: 'Associated picoCTF problem ID, if this is a picoCTF level' }

      #- denormalized into Level and automatically set by campaign editor
      campaign: c.shortString title: 'Campaign', description: 'Which campaign this level is part of (like "desert").', format: 'hidden'
      campaignIndex: c.int title: 'Campaign Index', description: 'The 0-based index of this level in its campaign.', format: 'hidden'

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
    }

  }}
}


c.extendBasicProperties CampaignSchema, 'campaign'
c.extendTranslationCoverageProperties CampaignSchema
c.extendPatchableProperties CampaignSchema

module.exports = CampaignSchema
