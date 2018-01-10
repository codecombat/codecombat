c = require './../schemas'

PaymentSchema = c.object({title: 'Payment', required: []}, {
  purchaser: c.objectId(links: [ {rel: 'extra', href: '/db/user/{($)}'} ]) # in case of gifts
  recipient: c.objectId(links: [ {rel: 'extra', href: '/db/user/{($)}'} ])
  purchaserEmailLower: c.shortString(description: 'We may have a purchaser with no account, in which case only this email will be set')

  service: { enum: ['stripe', 'ios', 'external', 'paypal']}
  amount: { type: 'integer', description: 'Payment in cents.' }
  created: c.date({title: 'Created', readOnly: true})
  gems: { type: 'integer', description: 'The number of gems acquired.' }
  productID: { type: 'string', description: 'The "name" field for the product purchased' }
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

  payPal: { 
    title: 'PayPal Payment Data',
    description: 'The payment object as received from PayPal' 
  }
  payPalSale: { 
    title: 'PayPal Payment Sale Data',
    description: 'The payment sale object as received from PayPal' 
  }
  payPalBillingAgreementID: { type: 'string', description: 'Used to connect initial subscribe payments with recurring payments.' }
})

c.extendBasicProperties(PaymentSchema, 'payment')

module.exports = PaymentSchema
