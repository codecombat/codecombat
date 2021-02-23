const schema = require('./../schemas')

const DistrictSchema = schema.object({}, {
  name: schema.shortString(),
  properties: schema.object({
    title: 'District properties',
    additionalProperties: true
  }, {
    countryName: schema.shortString(),
    ncesId: schema.shortString(),
    district_schools: schema.int(),
    district_students: schema.int()
  })
})

schema.extendBasicProperties(DistrictSchema, 'district')

module.exports = DistrictSchema
