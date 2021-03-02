const schema = require('./../schemas')

const DistrictSchema = schema.object({ required: ['name'] }, {
  name: schema.shortString(),
  ncesId: { type: 'string', minLength: 7, maxLength: 7 },
  type: schema.shortString({ description: 'Type of district' }),
  schools: schema.int({ description: 'Total operational schools' }),
  students: schema.int({ description: 'Total students' }),
  teachers: schema.int({ description: 'Total full time equivalent teachers' }),
  phone: schema.shortString({ description: 'Phone number' }),
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
      zip: { type: 'string', description: 'Postal code' }, // Can have leading 0's
      address: schema.shortString({ description: 'Address of district' }),
      localeCode: schema.shortString({ description: 'The Urban Centric Locale code for a school' })
    }
  )
})

schema.extendBasicProperties(DistrictSchema, 'district')

module.exports = DistrictSchema
