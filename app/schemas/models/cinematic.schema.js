const c = require('./../schemas')

const CharacterSchema = (title) => c.object({
  title: title,
  description: 'ThangType that will appear on the right side of the screen.'
}, {
  type: c.shortString({
    title: 'Type',
    description: 'Whether this is the player hero, a thangType slug or null.',
    enum: ['slug', 'hero', 'null'],
    default: 'null'
  }),
  slug: c.shortString({
    title: 'ThangType Slug',
    description: 'Required if type is set to `slug`'
  }),
  enterOnStart: {
    type: 'boolean'
  }
})

const ShotSetup = c.object({
  title: 'ShotSetup'
}, {
  cameraType: c.shortString({
    title: 'Camera Type',
    description: 'The shot type',
    enum: ['right-close', 'left-close', 'dual'],
    default: 'dual'
  }),
  rightThangType: CharacterSchema('Right Character'),
  leftThangType: CharacterSchema('Left Character'),
  backgroundArt: c.object({
    title: 'Background Art',
    description: 'The art in the background of this shot.'
  }, {
    type: c.shortString({ enum: ['slug', 'null'] }),
    slug: c.shortString({
      title: 'Background path',
      description: 'Path to the background asset'
    })
  })
  // TODO: music
  // TODO: next - id
})

const DialogNode = c.object({
  title: 'Dialog Node',
  description: 'A node of a shot. Contains dialog instructions.',
  required: ['dialogClear']
}, {
  speaker: c.shortString({ enum: ['left', 'right'], title: 'Speaker', description: 'Which character is speaking. Used to select speech bubble.' }),
  text: { type: 'string', title: 'Text', description: 'html text. TODO: how to translate this and interpolate this???' },
  textLocation: c.object({ title: 'Text Location', description: 'An {x, y} coordinate point.', format: 'point2d', required: ['x', 'y'] }, {
    x: { title: 'x', description: 'The x coordinate.', type: 'number', 'default': 0 },
    y: { title: 'y', description: 'The y coordinate.', type: 'number', 'default': 0 } }),
  action: c.shortString({ title: 'Action', description: 'The action or animation to play on the speaker.' }),
  triggers: c.object({
    title: 'Triggers',
    description: 'Events that can occur during the dialogue.'
  }, {
    changeBackground: c.object({
      title: 'Change Background',
      description: 'Change the background image of the cinematic',
      required: ['art', 'triggerStart']
    }, {
      art: c.shortString({ title: 'Art', description: 'The background art path' }),
      triggerStart: c.int({ title: 'Trigger Start(ms)', description: 'The number of milliseconds until the background changes.' })
    }),
    backgroundObject: c.object({
      title: 'Background Object',
      description: 'Add a background object after given duration',
      required: ['art', 'triggerStart']
    }, {
      thangType: c.shortString({ title: 'Art', description: 'The background image ThangType slug.' }),
      triggerStart: c.int({ title: 'Trigger Start(ms)', description: 'The number of milliseconds until background image art appears' })
    }),
    clearObjects: c.object({
      title: 'Clear Object',
      description: 'Clears the background objects from the screen after a given duration'
    }, {
      triggerStart: c.int({ title: 'Trigger Start(ms)', description: 'The number of milliseconds until background object is cleared' })
    }),
    animationTrigger: c.object({
      title: 'Animation Trigger',
      description: 'Trigger to fire an animation on a character.',
      required: ['character', 'animation', 'triggerStart']
    }, {
      character: c.shortString({ title: 'Character', enum: ['left', 'right', 'background-object'] }),
      animation: c.shortString({ title: 'Animation', description: 'The action or animation to play on the lank.' }),
      triggerStart: c.int({ title: 'Trigger Start(ms)', description: 'The number of milliseconds until animation plays' })
    }),
    soundEffect: c.sound({
      triggerStart: c.int({ title: 'Trigger Start(ms)', description: 'The number of millisecond before sound effect plays' })
    }),
    // soundEffect: c.sound({
    //   triggerStart: c.int({ title: 'Trigger Start(ms)', description: 'The number of millisecond before sound effect plays' })
    // }),
    cameraShake: c.object({
      title: 'Camera shake',
      description: 'Shakes the camera.',
      required: ['triggerStart']
    }, {
      triggerStart: c.int({ title: 'Trigger Start(ms)', description: 'The number of milliseconds until camera shakes' })
    })
  }),
  dialogClear: {
    type: 'boolean',
    title: 'Dialog Clear on End',
    description: 'Whether or not all dialog nodes are cleared from screen or left up.'
  },
  exitRightCharacter: { title: 'Exit Right Character', description: 'whether right character exits at dialog node completion', type: 'boolean' },
  exitLeftCharacter: { title: 'Exit Left Character', description: 'whether left character exits at dialog node completion', type: 'boolean' }
  // TODO: next node
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
