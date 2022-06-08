const schema = require('./../schemas')

const PodcastSchema = schema.object(
  {
    title: 'Podcast Episode',
    required: ['name']
  },
  {
    name: schema.shortString(),
    description: { type: 'string' },
    guestName: schema.shortString(),
    guestDetails: { type: 'string' },
    guestImage: { type: 'string', format: 'image-file' },
    transcript: schema.file(),
    uploadDate: schema.date(),
    transistorEpisodeId: schema.shortString(),
    audio: schema.sound()
  }
)

schema.extendBasicProperties(PodcastSchema, 'podcast')
schema.extendSearchableProperties(PodcastSchema)

module.exports = PodcastSchema
