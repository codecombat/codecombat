const schema = require('./../schemas')

const PodcastSchema = schema.object(
  {
    title: 'Podcast Episode',
    required: ['name']
  },
  {
    name: schema.shortString(),
    description: { type: 'string', format: 'markdown' },
    shortDescription: { type: 'string', format: 'markdown' },
    guestName: schema.shortString(),
    guestDetails: { type: 'string', format: 'markdown' },
    guestImage: { type: 'string', format: 'image-file' },
    transcript: schema.file(),
    uploadDate: schema.date(),
    transistorEpisodeId: schema.shortString(),
    audio: schema.sound(),
    i18n: { type: 'object', format: 'i18n', props: ['name', 'description', 'guestName', 'guestDetails'] }
  }
)

schema.extendBasicProperties(PodcastSchema, 'podcast')
schema.extendSearchableProperties(PodcastSchema)
schema.extendNamedProperties(PodcastSchema)
schema.extendTranslationCoverageProperties(PodcastSchema)
schema.extendPatchableProperties(PodcastSchema)

module.exports = PodcastSchema
