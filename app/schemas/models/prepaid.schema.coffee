c = require './../schemas'

PrepaidSchema = c.object({title: 'Prepaid', required: ['creator', 'type']}, {
  creator: c.objectId(links: [ {rel: 'extra', href: '/db/user/{($)}'} ])
  redeemers: c.array {}, c.objectId(links: [ {rel: 'extra', href: '/db/user/{($)}'} ])
  maxRedeemers: { type: 'integer'}
  code: c.shortString(title: "Unique code to redeem")
  type: { type: 'string' }
  properties: {type: 'object'}
  # Deprecated
  status: { enum: ['active', 'used'], default: 'active' }
  redeemer: c.objectId(links: [ {rel: 'extra', href: '/db/user/{($)}'} ])
})

c.extendBasicProperties(PrepaidSchema, 'prepaid')

module.exports = PrepaidSchema
