const schema = require('./../schemas')

const CutsceneSchema = schema.object({
  description: 'Data for a cinematic',
  title: 'Cutscene'
}, {
  // Deprecated. Instead upload and use Cloudflare.
  vimeoId: schema.shortString({
    title: 'VimeoID',
    description: '"DEPRECATED - Upload to Cloudflare instead." - The id of the vimeo video we want to play.'
  }),
  cloudflareID: schema.shortString({
    title: 'Cloudflare ID',
    description: 'Cloudflare video stream ID'
  }),
  chinaVideoSrc: schema.shortString({
    title: 'Video URL for China',
    description: 'Raw video URL for china. Recommend this video is stored in the aliyun S3 equivalent OSS.'
  }),
  captions: schema.object({}, {
    src: { type: 'string', title: 'Caption file', format: 'vtt-file', description: "If this vtt file doesn't upload you may need to use a different browser like Firefox." },
    label: schema.shortString({ title: 'Language Label' })
  }),
  i18n: { type: 'object', format: 'i18n', props: ['name', 'captions', 'displayName'], description: 'This cutscene translation required srt files.' },
  displayName: schema.shortString({ title: 'Display Name' }),
  description: { type: 'string', title: 'Description', description: 'Relevant for teacher dashboard' }
})

schema.extendBasicProperties(CutsceneSchema, 'cutscene')
schema.extendTranslationCoverageProperties(CutsceneSchema)
schema.extendPatchableProperties(CutsceneSchema)
schema.extendNamedProperties(CutsceneSchema)

module.exports = CutsceneSchema
