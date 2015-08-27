c = require './../schemas'

AnalyticsStripeInvoiceSchema = c.object {
  title: 'Analytics Stripe Invoice'
}

_.extend AnalyticsStripeInvoiceSchema.properties,
  _id: {type: 'string'}
  date: {type: 'integer'}
  properties: {type: 'object'}

c.extendBasicProperties AnalyticsStripeInvoiceSchema, 'analytics.stripe.invoice'

module.exports = AnalyticsStripeInvoiceSchema
