c = require './../schemas'

CourseInstanceSchema = c.object {title: 'Course Instance'}

_.extend CourseInstanceSchema.properties,
  courseID: c.objectId()
  description: {type: 'string'}
  members: c.array {title: 'Members'}, c.objectId()
  name: {type: 'string'}
  ownerID: c.objectId()
  prepaidID: c.objectId()

c.extendBasicProperties CourseInstanceSchema, 'CourseInstance'

module.exports = CourseInstanceSchema
