c = require './../schemas'

LevelFeedbackLevelSchema = c.object {required: ['original', 'majorVersion']}, {
  original: c.objectId({})
  majorVersion: {type: 'integer', minimum: 0 }}

LevelFeedbackSchema = c.object {
  title: 'Feedback'
  description: 'Feedback on a level.'
}

_.extend LevelFeedbackSchema.properties,
  # denormalization
  creatorName: {type: 'string'}
  levelName: {type: 'string'}
  levelID: {type: 'string'}

  creator: c.objectId(links: [{rel: 'extra', href: '/db/user/{($)}'}])
  created: c.date({title: 'Created', readOnly: true})

  level: LevelFeedbackLevelSchema
  rating: {type: 'number', minimum: 1, maximum: 5}
  review: {type: 'string'}

c.extendBasicProperties LevelFeedbackSchema, 'level.feedback'

module.exports = LevelFeedbackSchema
