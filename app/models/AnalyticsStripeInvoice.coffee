CocoModel = require './CocoModel'

module.exports = class AnalyticsStripeInvoice extends CocoModel
  @className: 'AnalyticsStripeInvoice'
  @schema: require 'schemas/models/analytics_stripe_invoice'
  urlRoot: '/db/analytics.stripe.invoice'
