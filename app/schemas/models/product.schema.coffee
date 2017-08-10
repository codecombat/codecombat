c = require './../schemas'

module.exports = ProductSchema = {
  type: 'object'
  additionalProperties: false
  properties: {
    name: { type: 'string' }
    amount: { type: 'integer', description: 'Cost in cents' }
    gems: { type: 'integer', description: 'Number of gems awarded' }
    coupons: {
      type: 'array'
      items: {
        type: 'object'
        additionalProperties: false
        properties: {
          code: { type: 'string' }
          amount: { type: 'integer', description: 'Adjusted cost in cents' }
        }
      }
    }
    payPalBillingPlanID: { type: 'string' }
  }
}

c.extendBasicProperties ProductSchema, 'Product'
