const schema = require('./../schemas')

const PodcastSchema = schema.object(
  {
    title: 'Podcast Episode',
    required: ['name']
  },
  {
    name: schema.shortString(),
    details: { type: 'string' },
    guestName: schema.shortString(),
    guestDetails: { type: 'string' },
    guestImage: { type: 'string', format: 'image-file' },
    transcriptUrl: schema.url(),
    uploadDate: schema.date(),
    transistorEpisodeId: schema.shortString(),
    audioUrl: { type: 'string', format: 'file' }
  }
)

schema.extendBasicProperties(PodcastSchema, 'podcast')
schema.extendSearchableProperties(PodcastSchema)

module.exports = PodcastSchema
