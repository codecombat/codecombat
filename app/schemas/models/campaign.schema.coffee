c = require './../schemas'

CampaignSchema = c.object()
c.extendNamedProperties CampaignSchema  # name first

_.extend CampaignSchema.properties, {
  i18n: {type: 'object', title: 'i18n', format: 'i18n', props: ['name', 'body']}

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
      showIfUnlocked: { type: 'string', links: [{rel: 'db', href: '/db/level/{($)}/version'}], format: 'latest-version-original-reference' }
    }
  }}

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
      requiresSubscription: { type: 'boolean' }
      type: {'enum': ['campaign', 'ladder', 'ladder-tutorial', 'hero', 'hero-ladder', 'hero-coop']}
      slug: { type: 'string', format: 'hidden' }
      original: { type: 'string', format: 'hidden' }
      adventurer: { type: 'boolean' }
      practice: { type: 'boolean' }
      adminOnly: { type: 'boolean' }
      disableSpaces: { type: 'boolean' }
      hidesSubmitUntilRun: { type: 'boolean' }
      hidesPlayButton: { type: 'boolean' }
      hidesRunShortcut: { type: 'boolean' }
      hidesHUD: { type: 'boolean' }
      hidesSay: { type: 'boolean' }
      hidesCodeToolbar: { type: 'boolean' }
      hidesRealTimePlayback: { type: 'boolean' }
      backspaceThrottle: { type: 'boolean' }
      lockDefaultCode: { type: 'boolean' }
      moveRightLoopSnippet: { type: 'boolean' }
      realTimeSpeedFactor: { type: 'number' }
      autocompleteFontSizePx: { type: 'number' }

      requiredCode: c.array {}, {
        type: 'string'
      }
      suspectCode: c.array {}, {
        type: 'object'
        properties: {
          name: { type: 'string' }
          pattern: { type: 'string' }
        }
      }

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

      #- denormalized from Achievements
      rewards: { type: 'array', items: {
        type: 'object'
        additionalProperties: false
        properties:
          achievement: { type: 'string', links: [{rel: 'db', href: '/db/achievement/{{$}}'}], format: 'achievement' }
          item: { type: 'string', links: [{rel: 'db', href: '/db/thang.type/{($)}/version'}], format: 'latest-version-original-reference' }
          hero: { type: 'string', links: [{rel: 'db', href: '/db/thang.type/{($)}/version'}], format: 'latest-version-original-reference' }
          level: { type: 'string', links: [{rel: 'db', href: '/db/level/{($)}/version'}], format: 'latest-version-original-reference' }
          type: { enum: ['heroes', 'items', 'levels'] }
      }}
      campaign: c.shortString title: 'Campaign', description: 'Which campaign this level is part of (like "desert").', format: 'hidden'  # Automatically set by campaign editor.

      #- normal properties
      position: c.point2d()
    }

  }}
}


c.extendBasicProperties CampaignSchema, 'campaign'
c.extendTranslationCoverageProperties CampaignSchema

module.exports = CampaignSchema
