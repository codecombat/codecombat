c = require './../schemas'

# NOTE:
# Clan specific code has recently (Dec 2020) had many changes.
#
# Clans now exist in two variants:
# - Original clans made by users without 'kind' and 'displayName'
# - New "auto clans" made programatically without 'members'
#
# Avoid relying on 'members', and rather look up the _id of
# a clan on the User.clans array.
# Avoid rendering only 'name', instead check for 'displayName' first like so:
# <h1>{{ clan.displayName || clan.name }}</h1>


ClanSchema = c.object {title: 'Clan', required: ['name', 'type']}
# TODO: Require name to be non-empty
c.extendNamedProperties ClanSchema

# Clan.name now has two main uses:
# - For original clans it remains the regular name, no changes
# - For auto clans, it is a unique ID for the origin of the programmatic creation
#
# Let's take a classroom as an example of an auto clan.
#
# Given a classroom with this data:
#
# _id: 'abc123'
# name: 'Computer Science 1'
#
# The following clan is created:
#
# name: '__classroom_abc123'
# members: []
# ownerID: '512ef4805a67a8c507000001' # Nick's ID
# type: 'public'
# dashboardType: 'basic'
# kind: 'classroom'
# displayName: 'Computer Science 1'

_.extend ClanSchema.properties,
  description: {type: 'string', format: 'markdown'}
  # Empty for auto clans
  members: c.array {title: 'Members'}, c.objectId()
  # Optional property
  ownerID: c.objectId()
  # Set to 'public' for auto clans
  type: {type: 'string', 'enum': ['public', 'private'], description: 'Controls clan general visibility.'}
  # Set to 'basic' for auto clans
  dashboardType: {type: 'string', 'enum': ['basic', 'premium']}
  # Set only for auto clans, to the origins of the programmatic creation
  kind: {
    type: 'string',
    enum: ['classroom', 'teacher', 'school', 'school-subnetwork', 'school-network', 'school-district', 'administrative-region', 'country'],
    description: 'Signals an autoclan that may use different logic to look up membership'
  }
  metadata: c.object({
    title: 'Metadata',
    description: 'Contains properties that help find autoclans'
    additionalProperties: true
  })
  displayName: { type: 'string', description: 'overwrites visual visual name of clan - used as name is tied to the slug' }
  esportsImage: { type: 'string', format: 'image-file', title: 'Esports Image', description: 'Image to show for this team on league page.' }

c.extendBasicProperties ClanSchema, 'Clan'

# Do we need these?
# c.extendSearchableProperties ClanSchema
# c.extendPermissionsProperties ClanSchema

module.exports = ClanSchema
