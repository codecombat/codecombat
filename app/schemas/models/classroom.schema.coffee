c = require './../schemas'

ClassroomSchema = c.object {title: 'Classroom', required: ['name']}
c.extendNamedProperties ClassroomSchema  # name first

_.extend ClassroomSchema.properties,
  members: c.array {title: 'Members'}, c.objectId()
  ownerID: c.objectId()
  description: {type: 'string'}
  code: c.shortString(title: "Unique code to redeem")
  aceConfig:
    language: {type: 'string', 'enum': ['python', 'javascript']}

c.extendBasicProperties ClassroomSchema, 'Classroom'

module.exports = ClassroomSchema
