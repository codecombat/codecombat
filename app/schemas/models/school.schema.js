const schema = require('./../schemas')

const SchoolSchema = schema.object(
  {
    title: 'School',
    description:
      'A school or school-level educational institution or business location, potentially belonging to a school district or other educational network',
    required: ['name']
  },
  {
    district: schema.objectId({
      links: [{ rel: 'extra', href: '/db/district/{($)}' }]
    }),
    name: schema.shortString(),
    ncesId: { type: 'string', minLength: 12, maxLength: 12 },
    type: schema.shortString({ description: 'Type of school' }),
    phone: schema.shortString({ description: 'Phone number' }),
    students: schema.int({ description: 'Total students all grades' }),
    teachers: schema.int({ description: 'Full-Time equivalent teachers' }),
    level: schema.shortString({ description: 'School Level' }),
    website: schema.shortString({ description: 'Website' }),
    geo: schema.object(
      {},
      {
        country: { description: '2 letter ISO-3166-1 country code' },
        countryName: { description: 'Full country name' },
        region: { description: '2 character region code' },
        regionName: { description: 'Full region name -- use for full state name' },
        county: { description: 'County Name' },
        city: { description: 'Full city name' },
        ll: schema.array(
          {},
          { description: 'Latitude and longitude of the city' }
        ),
        metro: { description: 'Metro code' },
        zip: { type: 'string', description: 'Postal code' },
        address: schema.shortString({ description: 'Address of school' }),
        localeCode: schema.shortString({ description: 'The Urban Centric Locale code for a school' })
      }
    )
  }
)

schema.extendBasicProperties(SchoolSchema, 'school')

module.exports = SchoolSchema
