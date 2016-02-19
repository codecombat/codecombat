c = require './../schemas'

PaymentSchema = c.object({title: 'Payment', required: []}, {
  purchaser: c.objectId(links: [ {rel: 'extra', href: '/db/user/{($)}'} ]) # in case of gifts
  recipient: c.objectId(links: [ {rel: 'extra', href: '/db/user/{($)}'} ])

  service: { enum: ['stripe', 'ios', 'external']}
  amount: { type: 'integer', description: 'Payment in cents.' }
  created: c.date({title: 'Created', readOnly: true})
  gems: { type: 'integer', description: 'The number of gems acquired.' }
  productID: { enum: ['gems_5', 'gems_10', 'gems_20', 'custom']}
  description: { type: 'string' }
  prepaidID: c.objectId()

  ios: c.object({title: 'iOS IAP Data'}, {
    transactionID: { type: 'string' }
    rawReceipt: { type: 'string' }
    localPrice: { type: 'string' }
  })

  stripe: c.object({title: 'Stripe Data'}, {
    timestamp: { type: 'integer', description: 'Unique identifier provided by the client, to guard against duplicate payments.' }
    chargeID: { type: 'string' }
    customerID: { type: 'string' }
    invoiceID: { type: 'string' }
  })
})

c.extendBasicProperties(PaymentSchema, 'payment')

module.exports = PaymentSchema
