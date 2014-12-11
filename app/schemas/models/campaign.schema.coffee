
c = require './../schemas'

CampaignSchema = c.object()
c.extendNamedProperties CampaignSchema  # name first

_.extend CampaignSchema.properties,
  i18n: {type: 'object', title: 'i18n', format: 'i18n', props: ['name', 'body']}
  
  ambientSound: c.object {},
    mp3: { type: 'string', format: 'sound-file' }
    ogg: { type: 'string', format: 'sound-file' }
    
  backgroundImage: c.array {}, {
    image: { type: 'string', format: 'image-file' }
    width: { type: 'number' }
  }
  backgroundColor: { type: 'string' }
  backgroundColorTransparent: { type: 'string' }
  
  adjacentCampaigns: { type: 'object', additionalItems: {
    title: 'Campaign'
    type: 'object'
    properties: {
      #- denormalized from other Campaigns, either updated automatically or fetched dynamically
      name: { type: 'string' }
      i18n: { type: 'object' }
      
      #- normal properties
      position: c.point2d()
      rotation: { type: 'number', format: 'degrees' }
      color: { type: 'string' }
    }
  }}
  
  levels: { type: 'object', additionalItems: {
    title: 'Level'
    type: 'object'
    properties: {
      #- denormalized from Level
      # TODO: take these properties from the Level schema and put them into schema references, use them here
      name: { readOnly: true }
      description: { readOnly: true }
      requiresSubscription: { type: 'boolean' }
      type: {'enum': ['campaign', 'ladder', 'ladder-tutorial', 'hero', 'hero-ladder', 'hero-coop']}
      slug: { readOnly: true }
      original: { readOnly: true }
      adventurer: { type: 'boolean' }
      practice: { type: 'boolean' }
      
      # TODO: add these to the level, as well as the 'campaign' property
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
        type: 'string' # should be an originalID, denormalized on the editor side
      }}
      restrictedGear: { type: 'object', additionalProperties: {
        type: 'string' # should be an originalID, denormalized on the editor side
      }}
      allowedHeroes: { type: 'array', items: {
        type: 'string' # should be an originalID, denormalized on the editor side
      }}

      #- denormalized/restructured from Achievements
      nextLevels: c.array {}
      unlocksHero: c.object { readOnly: true }, {
        image: { type: 'string', format: 'image-file' }
        original: { type: 'string' }
      }

      #- normal properties
      position: c.point2d()
      
    }
  }
}

c.extendBasicProperties CampaignSchema, 'campaign'
c.extendTranslationCoverageProperties CampaignSchema

module.exports = CampaignSchema
