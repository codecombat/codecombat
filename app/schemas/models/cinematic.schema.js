const c = require('./../schemas')

// const CharacterSchema = (title) => c.object({
//   title: title,
//   description: 'ThangType that will appear on the right side of the screen.'
// }, {
//   type: c.shortString({
//     title: 'Type',
//     description: 'Whether this is the player hero, a thangType slug or null.',
//     enum: ['slug', 'hero', 'null'],
//     default: 'null'
//   }),
//   slug: c.shortString({
//     title: 'ThangType Slug',
//     description: 'Required if type is set to `slug`'
//   }),
//   enterOnStart: {
//     type: 'boolean'
//   }
// })

// const ShotSetup = c.object({
//   title: 'ShotSetup'
// }, {
//   cameraType: c.shortString({
//     title: 'Camera Type',
//     description: 'The shot type',
//     enum: ['right-close', 'left-close', 'dual'],
//     default: 'dual'
//   }),
//   rightThangType: CharacterSchema('Right Character'),
//   leftThangType: CharacterSchema('Left Character'),
//   backgroundArt: c.object({
//     title: 'Background Art',
//     description: 'The art in the background of this shot.'
//   }, {
//     type: c.shortString({ enum: ['slug', 'null'] })
//   })
// })

const CinematicSchema = c.object({
  description: 'A cinematic composed of shots.',
  title: 'Cinematic'
}, {
  shots: c.array({
    title: 'Shots',
    description: 'Ordered list of shots that make up a cinematic',
    default: []
  }, {
    shot: c.stringID({
      title: 'Shot',
      description: 'A reference to the shot.',
      links: [{ rel: 'db', href: '/db/shot/{($)}' }]
    })
  })
})

c.extendBasicProperties(CinematicSchema, 'cinematic')
c.extendNamedProperties(CinematicSchema)
