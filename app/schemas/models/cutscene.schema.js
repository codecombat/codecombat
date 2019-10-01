const schema = require('./../schemas')

const CutsceneSchema = schema.object({
  description: 'Data for a cinematic',
  title: 'Cutscene'
}, {
  vimeoId: schema.shortString({
    title: 'VimeoID',
    description: 'The id of the vimeo video we want to play.'
  })
})

schema.extendBasicProperties(CutsceneSchema, 'cutscene')
schema.extendNamedProperties(CutsceneSchema)

module.exports = CutsceneSchema
