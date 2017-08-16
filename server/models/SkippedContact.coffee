# TODO: Somehow keep this in sync with sales repo?

mongoose = require('mongoose')
co = require('co')
jsonSchema = require '../../app/schemas/models/skipped_contact.schema'

schema = mongoose.Schema(
  {
    zpContact: { type: 'object' }
    reason: { type: 'string' }
    archived: { type: 'boolean' }
  },
  { strict: false, bufferCommands: false }
)
schema.index({'zpContact.id': 1}, {unique: true, sparse: true})
schema.index({'trialRequest._id': 1}, {unique: true, sparse: true})
schema.statics.editableProperties = [
  'archived'
]

schema.statics.jsonSchema = jsonSchema
SkippedContact = mongoose.model('SkippedContact', schema, 'skipped.contacts')

module.exports = SkippedContact
