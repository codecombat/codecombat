c = require './../schemas'

ClanSchema = c.object {title: 'Clan', required: ['name', 'type']}
c.extendNamedProperties ClanSchema  # name first

_.extend ClanSchema.properties,
  name: c.shortString()
  type: {type: 'string', 'enum': ['public']}
  ownerID: c.objectId()
  ownerName: c.shortString()
  members: c.array {title: 'Members'},
    c.object {required: ['id', 'name', 'level']},
      id: c.objectId()
      name: c.shortString()
      level: {type: 'integer'}

c.extendBasicProperties ClanSchema, 'Clan'

# Do we need these?
# c.extendSearchableProperties ClanSchema
# c.extendPermissionsProperties ClanSchema

module.exports = ClanSchema
