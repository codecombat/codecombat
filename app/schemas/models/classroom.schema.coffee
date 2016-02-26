c = require './../schemas'

ClassroomSchema = c.object {title: 'Classroom', required: ['name']}
c.extendNamedProperties ClassroomSchema  # name first

_.extend ClassroomSchema.properties,
  members: c.array {title: 'Members'}, c.objectId()
  ownerID: c.objectId()
  description: {type: 'string'}
  code: c.shortString(title: "Unique code to redeem")
  codeCamel: c.shortString(title: "UpperCamelCase version of code for display purposes")
  aceConfig:
    language: {type: 'string', 'enum': ['python', 'javascript']}
  averageStudentExp: { type: 'string' }
  ageRangeMin: { type: 'string' }
  ageRangeMax: { type: 'string' }

c.extendBasicProperties ClassroomSchema, 'Classroom'

module.exports = ClassroomSchema
