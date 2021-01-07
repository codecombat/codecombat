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
  # Set only for auto clans, to the origins of the programmatic creation
  kind: {
    type: 'string',
    enum: ['classroom', 'teacher', 'school', 'school-network', 'school-subnetwork', 'school-district', 'administrative-region', 'country'],
    description: 'Signals an autoclan that may use different logic to look up membership'
  }
  # Set only for auto clans (yet), to display instead of Clan.name
  displayName: { type: 'string' }
  metadata: c.object({
    title: 'Metadata',
    description: 'Contains properties that help find autoclans'
    additionalProperties: true
  })

c.extendBasicProperties ClanSchema, 'Clan'

# Do we need these?
# c.extendSearchableProperties ClanSchema
# c.extendPermissionsProperties ClanSchema

module.exports = ClanSchema
