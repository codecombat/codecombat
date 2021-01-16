const c = require('./../schemas')
const { LEFT_LANK_KEY, RIGHT_LANK_KEY, HERO_PET, BACKGROUND_OBJECT } = require('./../../../ozaria/engine/cinematic/constants')

const ThangTypeSchema = (title, description) => c.object({
  title,
  description,
  required: ['type']
}, {
  type: {
    oneOf: [
      c.shortString({
        title: 'Hero',
        description: 'Hero ThangType Id computed at runtime',
        enum: ['hero', 'avatar']
      }),
      c.object({
        title: 'Character Slug',
        description: 'The slug of the Character Thangtype.',
        required: ['slug']
      }, {
        slug: c.shortString({
          title: 'Slug',
          description: 'The thangType slug of the asset. Only required if this isn\'t the player hero.'
        })
      })
    ]
  },
  scaleX: c.float({
    title: 'scaleX',
    description: 'The scaling factor along x axis to apply to the ThangType'
  }),
  scaleY: c.float({
    title: 'scaleY',
    description: 'The scaling factor along y axis to apply to the ThangType'
  }),
  pos: c.point2d({
    title: 'Position',
    description: 'The position in meters to place the thangType.'
  })
})

const CharacterSchema = (title) => c.object({
  title: title,
  description: 'ThangType that will appear on either the left or right side of the screen.',
  required: ['thangType']
}, {
  thangType: ThangTypeSchema('Character', 'The thangType to display for this character'),
  enterOnStart: {
    type: 'boolean',
    title: 'Animate in?',
    description: 'If true the character will animate in. Otherwise the character will start simply there.'
  }
})

const ShotSetup = c.object({
  title: 'ShotSetup'
}, {
  shotContentType: c.shortString({ title: 'Content Type', description: 'Sets flag that all following shots are marked with, until this setting is used again. No runtime impact.', enum: ['story', 'education'], default: 'story' }),
  rightThangType: CharacterSchema('Right Character'),
  leftThangType: CharacterSchema('Left Character'),
  heroPetThangType: ThangTypeSchema('Hero Pet', 'The position property will be used to place the dog at an offset on the right lank.'),
  backgroundArt: ThangTypeSchema('Background Art', 'The rasterized image to place on the background'),
  camera: c.object({
    title: 'Camera placement',
    description: 'Where to place the camera at the beginning of the shot'
  }, {
    pos: c.point2d({
      title: 'Position',
      description: 'The position of the camera in meters.'
    }),
    zoom: {
      title: 'Zoom',
      description: 'The zoom level of the camera. A good default is \'2.01\'. There is a bug with the value 2. Recommended you change between 0 and 10.',
      type: 'number'
    }
  }),
  music: {
    oneOf: [
      c.object(
        { title: 'Music' },
        {
          files: c.sound(),
          loop: { type: 'boolean', default: false }
        }),

      // Legacy sound schema.  Present for backwards compatibility.
      c.sound()
    ]
  }
})

const DialogNode = c.object({
  title: 'Dialog Node',
  description: 'A node of a shot. Contains dialog instructions.',
  format: 'cinematic-dialog'
}, {
  speaker: c.shortString({ enum: ['left', 'right', 'center'], title: 'Speaker', description: 'Which character is speaking. Used to select speech bubble.' }),
  text: { type: 'string', title: 'Text', description: 'html text', maxLength: 500 },
  voiceOver: c.voiceOver,
  widthOverride: c.int({ title: 'Text Width(%)', description: 'The percent width of the text dialogue box based on the users screen size. Default is 31.' }),
  textAnimationLength: c.int({ title: 'Text Animation Length(ms)', description: 'The number of milliseconds it takes for the text to animate in.' }),
  speakingAnimationAction: c.shortString({ title: 'Speaking Animation', description: 'The animation to play on the lank while the text is being animated. If not set will default to "talkNeutral"' }),
  i18n: { type: 'object', format: 'i18n', props: ['text'], description: 'Help translate this cinematic dialogNode.' },
  waitUserInput: { type: 'boolean', title: 'User Input?', description: 'Whether or not user input is required to continue to the next dialog node or shot setup. Defaults to true.' },
  textLocation: c.object({ title: 'Text Location', description: 'An {x, y} coordinate point.', format: 'point2d', required: ['x', 'y'] }, {
    x: { title: 'x', description: 'The x coordinate.', type: 'number', 'default': 0 },
    y: { title: 'y', description: 'The y coordinate.', type: 'number', 'default': 0 } }),
  programmingLanguageFilter: c.shortString({ enum: ['python', 'javascript'], title: 'Programming Language Filter', description: 'If set, this node is only shown if the user is using the programming language selected.' }),
  visualChalkBoardData: c.object({
    title: 'Visual Chalkboard Data'
  }, {
    chalkboardContent: {
      oneOf: [
        { title: 'Markdown Content', type: 'string', maxLength: 4000, description: 'Content to place in the chalkboard', format: 'markdown' },
        {
          type: 'object',
          title: 'Rich Text Content',
          format: 'rich-text'
        }
      ]
    },
    width: { title: 'width (%)', description: 'The chalkboard width.', type: 'number', 'default': 45 },
    height: { title: 'height (%)', type: 'number', 'default': 75 },
    xOffset: { title: 'X offset (%)', description: 'An offset from the center along x', type: 'number', 'default': 46 },
    yOffset: { title: 'Y offset (%)', description: 'An offset from the center along y', type: 'number', 'default': 26 }
  }),
  mutators: c.object({
    title: 'Mutators',
    description: 'Properties that change cinematic going forward'
  }, {
    changeDefaultIdles: c.array({
      title: 'List of idles to change',
      description: 'Changes the action that is run for the idle state for provided character'
    },
    c.object({
      title: 'Change Idle Action',
      description: 'Setting this will update the default idle action for the rest of the cinematic. The default value is \'idle\'.'
    }, {
      character: c.shortString({ title: 'Character', description: 'Which character has default idle action updated', enum: [LEFT_LANK_KEY, RIGHT_LANK_KEY, BACKGROUND_OBJECT] }),
      newIdleAction: c.shortString({ title: 'New Idle Action' })
    })
    ),
    showVisualChalkboard: {
      title: 'Show Visual Chalkboard',
      type: 'boolean',
      description: 'Show the visual chalkboard',
      default: true
    },
    fadeToBlack: c.object({
      title: 'Fade To Black'
    }, {
      duration: c.int({ title: 'Duration(ms)', default: 400 })
    }),
    fadeFromBlack: c.object({
      title: 'Fade From Black'
    }, {
      duration: c.int({ title: 'Duration(ms)', default: 400 })
    })
  }),
  triggers: c.object({
    title: 'Triggers',
    description: 'Events that can occur during the dialogue.'
  }, {
    backgroundObject: c.object({
      title: 'Background Object',
      description: 'Add a background object after given duration',
      required: ['thangType', 'triggerStart']
    }, {
      thangType: ThangTypeSchema('Background Object', 'The image to place'),
      triggerStart: c.int({ title: 'Trigger Start(ms)', description: 'The number of milliseconds until background image art appears' })
    }),
    clearBackgroundObject: c.object({
      title: 'Clear Background Object',
      description: 'Clears the background objects from the screen after a given duration'
    }, {
      triggerStart: c.int({ title: 'Trigger Start(ms)', description: 'The number of milliseconds until background object is cleared' })
    }),
    playThangAnimations: c.array({
      title: 'Thang Animation triggers'
    }, c.object({
      title: 'Trigger Thang Action',
      description: 'Triggers an animation to play after a duration for a given time.',
      required: ['duration', 'animation', 'lankTarget']
    }, {
      delay: c.int({ title: 'Delay(ms)' }),
      duration: c.int({ title: 'Duration(ms)' }),
      animation: c.shortString({ title: 'Animation', description: 'Animation to trigger on the ThangType' }),
      lankTarget: c.shortString({ title: 'Thang', description: 'Thang on stage to play animation on', enum: [ LEFT_LANK_KEY, RIGHT_LANK_KEY, HERO_PET, BACKGROUND_OBJECT ] })
    })),
    soundFxTriggers: c.array({
      title: 'SoundFX triggers',
      description: 'A list of sound effects that we can play. Unlike music they will overlap and wont prevent other sounds playing.'
    },
    c.object({
      title: 'Sound Effect',
      description: 'A sound effect that plays after a delay.',
      required: ['sound']
    }, {
      sound: c.sound(),
      triggerStart: c.int({ title: 'Trigger Start(ms)', description: 'The number of milliseconds until the sound effect is played' })
    }))
  }),
  dialogClear: {
    type: 'boolean',
    title: 'Clear dialog on screen',
    description: 'Whether we clear any existing dialog nodes.'
  },
  exitCharacter: c.shortString({ title: 'Exit Character', description: 'whether character exits at dialog node completion', enum: ['left', 'right', 'both'] })
})

const Shot = c.object({
  title: 'Shot',
  description: 'A single shot, setting up camera and running dialog nodes'
}, {
  shotSetup: ShotSetup,
  dialogNodes: c.array({
    title: 'Dialog Nodes',
    description: 'List of all possible nodes in the shot.'
  }, DialogNode)
})

const CinematicSchema = c.object({
  description: 'A cinematic composed of shots.',
  title: 'Cinematic'
}, {
  i18n: { type: 'object', format: 'i18n', props: ['name', 'displayName'], description: 'Help translate this level' },
  shots: c.array({
    title: 'Shots',
    description: 'Ordered list of shots that make up a cinematic'
  }, Shot),
  displayName: c.shortString({ title: 'Display Name' }),
  description: { type: 'string', title: 'Description', description: 'Relevant for teacher dashboard' },
  showInstructionalTooltip: { title: 'Show Instructional Tooltip', description: 'Trigger instructions on how to navigate cinematics for users', type: 'boolean', default: true }
})

c.extendBasicProperties(CinematicSchema, 'cinematic')
c.extendNamedProperties(CinematicSchema)
c.extendTranslationCoverageProperties(CinematicSchema)
c.extendPatchableProperties(CinematicSchema)

module.exports = CinematicSchema
