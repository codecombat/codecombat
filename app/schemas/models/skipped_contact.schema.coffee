c = require './../schemas'

SkippedContactSchema = c.object {
  title: 'Skipped Contact'
}

_.extend SkippedContactSchema, # Let's have these on the bottom
  additionalProperties: true

c.extendBasicProperties SkippedContactSchema, 'skipped.contacts'
module.exports = SkippedContactSchema
