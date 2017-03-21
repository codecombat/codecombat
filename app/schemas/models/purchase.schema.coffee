c = require './../schemas'

purchaseables = ['level', 'thang_type']

PurchaseSchema = c.object({title: 'Purchase', required: ['purchaser', 'recipient', 'purchased']}, {
  purchaser: c.objectId(links: [
    {rel: 'extra', href: '/db/user/{($)}'}
  ]) # in case of gifts
  recipient: c.objectId(links: [
    {rel: 'extra', href: '/db/user/{($)}'}
  ])
  purchased: c.object({title: 'Target', required: ['collection', 'original']}, {
    collection: {enum: purchaseables}
    original: c.objectId(title: 'Target Original')
  })
  created: c.date({title: 'Created', readOnly: true})
})

c.extendBasicProperties(PurchaseSchema, 'patch')

module.exports = PurchaseSchema