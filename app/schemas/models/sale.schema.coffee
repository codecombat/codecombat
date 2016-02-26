c = require './../schemas'

sellables = ['level', 'thang_type']

SaleSchema = c.object({title: 'Sale', required: ['seller', 'recipient', 'sold']}, {
  seller: c.objectId(links: [
    {rel: 'extra', href: '/db/user/{($)}'}
  ]) # in case of gifts
  recipient: c.objectId(links: [
    {rel: 'extra', href: '/db/user/{($)}'}
  ])
  sold: c.object({title: 'Target', required: ['collection', 'original']}, {
    collection: {enum: sellables}
    original: c.objectId(title: 'Target Original')
  })
  created: c.date({title: 'Created', readOnly: true})
})

c.extendBasicProperties(SaleSchema, 'patch')

module.exports = SaleSchema