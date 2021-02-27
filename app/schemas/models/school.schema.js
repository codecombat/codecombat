const schema = require('./../schemas')

const SchoolSchema = schema.object({
  title: 'School',
  description: 'A school or school-level educational institution or business location, potentially belonging to a school district or other educational network'
}, {
  district: schema.objectId({ links: [ { rel: 'extra', href: '/db/district/{($)}' } ] }),
  city: schema.shortString(),
  state: schema.shortString(),
  countryName: schema.shortString(),
  county: schema.shortString(),
  phone: schema.shortString(),
  ncesId: schema.shortString(),
  students: schema.int(),
  zip: schema.shortString(),
  geoloc: schema.object({
    title: 'Geolog'
  }, {
    lat: schema.float({ title: 'lat' }),
    lng: schema.float({ title: 'lng' })
  })
})

schema.extendBasicProperties(SchoolSchema, 'school')
schema.extendNamedProperties(SchoolSchema)

module.exports = SchoolSchema
