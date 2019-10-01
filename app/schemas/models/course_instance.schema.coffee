c = require './../schemas'

CourseInstanceSchema = c.object {
  title: 'Course Instance'
#  required: [
#    'courseID', 'classroomID', 'members', 'ownerID', 'aceConfig'
#  ]
}

_.extend CourseInstanceSchema.properties,
  courseID: c.objectId()
  classroomID: c.objectId()
  description: {type: 'string'} # deprecated in favor of classrooms?
  members: c.array {title: 'Members'}, c.objectId()
  name: {type: 'string'} # deprecated in favor of classrooms?
  ownerID: c.objectId()
  prepaidID: c.objectId() # deprecated
  aceConfig:
    language: {type: 'string', 'enum': ['python', 'javascript']}
  hourOfCode: { type: 'boolean', description: 'Deprecated, do not use.' }
  stats: c.object({ additionalProperties: true })

c.extendBasicProperties CourseInstanceSchema, 'CourseInstance'

module.exports = CourseInstanceSchema
