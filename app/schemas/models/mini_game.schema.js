const _ = require('lodash')

const c = require('./../schemas')

const MiniGameSchema = c.object({
  title: 'Mini-Game',
  description: 'A Star Lab mini-game: a published code bundle plus the assets it needs, loaded at runtime by slug.',
})

// name first
c.extendNamedProperties(MiniGameSchema)

_.extend(MiniGameSchema.properties, {
  code: {
    type: 'string',
    title: 'Code Bundle',
    description: 'Published single-file IIFE game bundle (Phaser external), built in the codecombat-mini-games repo. Self-registers on window.CocoMiniGames[slug].',
    format: 'js-file',
  },
  images: c.array({ title: 'Images', description: 'Plain images. `key` is the logical name the game code looks up — filenames are not keys.' },
    c.object({ title: 'Image', required: ['key', 'image'] }, {
      key: c.shortString({ title: 'Key' }),
      image: { type: 'string', title: 'Image', format: 'image-file' },
    })),
  atlases: c.array({ title: 'Atlases', description: 'Texture atlases: image plus its TexturePacker JSON.' },
    c.object({ title: 'Atlas', required: ['key', 'image', 'data'] }, {
      key: c.shortString({ title: 'Key' }),
      image: { type: 'string', title: 'Texture Image', format: 'image-file' },
      data: { type: 'string', title: 'Atlas JSON', format: 'file' },
    })),
  sounds: c.array({ title: 'Sounds', description: 'Codec pairs: consumers hand the game both URLs and the engine picks per browser.' },
    c.sound({ key: c.shortString({ title: 'Key' }) })),
})

MiniGameSchema.required = ['name']

c.extendBasicProperties(MiniGameSchema, 'mini_game')
c.extendVersionedProperties(MiniGameSchema, 'mini_game')

module.exports = MiniGameSchema
