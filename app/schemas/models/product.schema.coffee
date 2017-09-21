c = require './../schemas'

module.exports = ProductSchema = {
  type: 'object'
  additionalProperties: false
  properties: {
    i18n: {type: 'object', title: 'i18n', format: 'i18n', props: ['displayName', 'displayDescription' ]}
    name: { type: 'string' }
    displayName: { type: 'string' }
    displayDescription: {type: 'string'}
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
          duration: { type: 'string', description: 'Stripe duration, only support once currently.'}
        }
      }
    }
    planID: { type: 'string', description: 'Probably should remove this' }
    payPalBillingPlanID: { type: 'string' }
  }
}

c.extendBasicProperties ProductSchema, 'Product'
c.extendTranslationCoverageProperties ProductSchema
c.extendPatchableProperties ProductSchema
