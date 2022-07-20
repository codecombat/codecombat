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
    transistorEpisodeId: { type: 'string', maxLength: 50, description: 'Go to transistor Episodes tab in dashboard -> Select episode -> Click social media landing page link -> Copy string you see in the url after https://share.transistor.fm/s/. Example value: 7e35f01c' },
    audio: schema.sound(),
    releasePhase: { enum: ['beta', 'internalRelease', 'released'], title: 'Release status', description: "Release status of the level, determining who sees it.", default: 'internalRelease' },
    i18n: { type: 'object', format: 'i18n', props: ['name', 'description', 'shortDescription', 'guestName', 'guestDetails'] },
    priority: { type: 'integer', description: 'higher the number, higher it will show up in podcast listing. Use current date as number for top listing so that we dont need to keep giving hugh numbers here. 2020-02-20 => 20200220'}
  }
)

schema.extendBasicProperties(PodcastSchema, 'podcast')
schema.extendSearchableProperties(PodcastSchema)
schema.extendNamedProperties(PodcastSchema)
schema.extendTranslationCoverageProperties(PodcastSchema)
schema.extendPatchableProperties(PodcastSchema)

module.exports = PodcastSchema
