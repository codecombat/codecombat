c = require './../schemas'

module.exports = ProductSchema = {
  type: 'object'
  additionalProperties: false
  properties: {
    name: { type: 'string' }
    amount: { type: 'integer', description: 'Cost in cents' }
    gems: { type: 'integer', description: 'Number of gems awarded' }
  }
}

c.extendBasicProperties ProductSchema, 'Product'
