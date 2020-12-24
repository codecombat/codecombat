c = require './../schemas'

# TODO: Require name to be non-empty

ClanSchema = c.object {title: 'Clan', required: ['name', 'type']}
c.extendNamedProperties ClanSchema  # name first

_.extend ClanSchema.properties,
  description: {type: 'string'}
  members: c.array {title: 'Members'}, c.objectId()
  ownerID: c.objectId()
  type: {type: 'string', 'enum': ['public', 'private'], description: 'Controls clan general visibility.'}
  dashboardType: {type: 'string', 'enum': ['basic', 'premium']}

c.extendBasicProperties ClanSchema, 'Clan'

# Do we need these?
# c.extendSearchableProperties ClanSchema
# c.extendPermissionsProperties ClanSchema

module.exports = ClanSchema
