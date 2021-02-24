const schema = require('./../schemas')

const DistrictSchema = schema.object({}, {
  countryName: schema.shortString(),
  ncesId: schema.shortString(),
  district_schools: schema.int(),
  district_students: schema.int()
})

schema.extendBasicProperties(DistrictSchema, 'district')
schema.extendNamedProperties(DistrictSchema)

module.exports = DistrictSchema
