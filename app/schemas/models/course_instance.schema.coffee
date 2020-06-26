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
    language: {type: 'string', 'enum': ['python', 'javascript', 'cpp']}
  hourOfCode: {type: 'boolean', description: 'Deprecated, do not use.'}
  stats: c.object({additionalProperties: true})
  startLockedLevel: c.shortString(description: 'Updated by teacher, lock this level and all following levels in a course')

c.extendBasicProperties CourseInstanceSchema, 'CourseInstance'

module.exports = CourseInstanceSchema
