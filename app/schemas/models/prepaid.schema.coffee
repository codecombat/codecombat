c = require './../schemas'

PrepaidSchema = c.object({title: 'Prepaid', required: ['creator', 'redeemer', 'type']}, {
  creator: c.objectId(links: [ {rel: 'extra', href: '/db/user/{($)}'} ])
  redeemer: c.objectId(links: [ {rel: 'extra', href: '/db/user/{($)}'} ])
  code: c.shortString(title: "Unique code to redeem")
  type: { type: 'string' }
  status: { enum: ['active', 'used'], default: 'active' }
  properties: {type: 'object'}
})

c.extendBasicProperties(PrepaidSchema, 'prepaid')

module.exports = PrepaidSchema
