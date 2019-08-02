const c = require('./../schemas')

const ThangTypeSchema = (title, description) => c.object({
  title,
  description,
  required: ['type']
}, {
  type: {
    oneOf: [
      c.shortString({
        title: 'Hero',
        description: 'Marker to inform us that this will be the players hero.',
        enum: ['hero']
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
  music: c.sound()
})

const DialogNode = c.object({
  title: 'Dialog Node',
  description: 'A node of a shot. Contains dialog instructions.'
}, {
  speaker: c.shortString({ enum: ['left', 'right'], title: 'Speaker', description: 'Which character is speaking. Used to select speech bubble.' }),
  text: { type: 'string', title: 'Text', description: 'html text', maxLength: 500 },
  textAnimationLength: c.int({ title: 'Text Animation Length(ms)', description: 'The number of milliseconds it takes for the text to animate in.' }),
  speakingAnimationAction: c.shortString({ title: 'Speaking Animation', description: 'The animation to play on the lank while the text is being animated.' }),
  i18n: { type: 'object', format: 'i18n', props: ['text'], description: 'Help translate this cinematic dialogNode.' },
  waitUserInput: { type: 'boolean', title: 'User Input?', description: 'Whether or not user input is required to continue to the next dialog node or shot setup. Defaults to true.' },
  textLocation: c.object({ title: 'Text Location', description: 'An {x, y} coordinate point.', format: 'point2d', required: ['x', 'y'] }, {
    x: { title: 'x', description: 'The x coordinate.', type: 'number', 'default': 0 },
    y: { title: 'y', description: 'The y coordinate.', type: 'number', 'default': 0 } }),
  programmingLanguageFilter: c.shortString({ enum: ['python', 'javascript'], title: 'Programming Language Filter', description: 'If set, this node is only shown if the user is using the programming language selected.' }),
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
  shots: c.array({
    title: 'Shots',
    description: 'Ordered list of shots that make up a cinematic'
  }, Shot)
})

c.extendBasicProperties(CinematicSchema, 'cinematic')
c.extendNamedProperties(CinematicSchema)

module.exports = CinematicSchema
