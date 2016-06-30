c = require './../schemas'

ClassroomSchema = c.object {title: 'Classroom', required: ['name']}
c.extendNamedProperties ClassroomSchema  # name first

_.extend ClassroomSchema.properties,
  name: { type: 'string', minLength: 1 }
  members: c.array {title: 'Members'}, c.objectId()
  deletedMembers: c.array {title: 'Deleted Members'}, c.objectId()
  ownerID: c.objectId()
  description: {type: 'string'}
  code: c.shortString(title: "Unique code to redeem")
  codeCamel: c.shortString(title: "UpperCamelCase version of code for display purposes")
  aceConfig:
    language: {type: 'string', 'enum': ['python', 'javascript']}
  averageStudentExp: { type: 'string' }
  ageRangeMin: { type: 'string' }
  ageRangeMax: { type: 'string' }
  archived:
    type: 'boolean'
    default: false
    description: 'Visual only; determines if the classroom is in the "archived" list of the normal list.'
  courses: c.array { title: 'Courses' }, c.object { title: 'Course' }, {
    _id: c.objectId()
    levels: c.array { title: 'Levels' }, c.object { title: 'Level' }, {
      practice: {type: 'boolean'}
      practiceThresholdMinutes: {type: 'number'}
      type: c.shortString()
      original: c.objectId()
      name: {type: 'string'}
      slug: {type: 'string'}
    }
  }

c.extendBasicProperties ClassroomSchema, 'Classroom'

module.exports = ClassroomSchema
