c = require './common'

FileSchema = c.baseSchema()

_.extend(FileSchema.properties, {
  filename: c.shortStringProp()
  contentType: c.shortStringProp()
  length: { type: 'number' }
  chunkSize: { type: 'number', format: 'hidden' }
  uploadDate: { type: 'string' }
  aliases: {}
  metadata:
    type: 'object'
    additionalProperties: false
    name: c.shortStringArrayProp()
    description: { type: 'string' }
    createdFor: { type: 'array', items: {}}
    path: { type: 'string' }
    creator: { type: 'string' }
})

c.extendSearchableProperties(FileSchema.properties.metadata)
FileSchema.format = 'file'

module.exports = FileSchema