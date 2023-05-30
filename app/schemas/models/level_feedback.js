// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
import c from './../schemas';

const LevelFeedbackLevelSchema = c.object({required: ['original', 'majorVersion']}, {
  original: c.objectId({}),
  majorVersion: {type: 'integer', minimum: 0 }});

const LevelFeedbackSchema = c.object({
  title: 'Feedback',
  description: 'Feedback on a level.'
});

_.extend(LevelFeedbackSchema.properties, {
  // denormalization
  creatorName: {type: 'string'},
  levelName: {type: 'string'},
  levelID: {type: 'string'},

  creator: c.objectId({links: [{rel: 'extra', href: '/db/user/{($)}'}]}),
  created: c.date({title: 'Created', readOnly: true}),

  level: LevelFeedbackLevelSchema,
  rating: {type: 'number', minimum: 1, maximum: 5},
  review: {type: 'string'}
});

c.extendBasicProperties(LevelFeedbackSchema, 'level.feedback');

export default LevelFeedbackSchema;
