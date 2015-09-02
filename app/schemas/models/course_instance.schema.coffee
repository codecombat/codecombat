c = require './../schemas'

CourseInstanceSchema = c.object {title: 'Course Instance'}
c.extendNamedProperties CourseInstanceSchema  # name first

_.extend CourseInstanceSchema.properties,
  description: {type: 'string'}
  members: c.array {title: 'Members'}, c.objectId()
  ownerID: c.objectId()
  prepaidID: c.objectId()

c.extendBasicProperties CourseInstanceSchema, 'CourseInstance'

module.exports = CourseInstanceSchema
