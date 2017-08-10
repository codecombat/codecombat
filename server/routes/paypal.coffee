errors = require '../commons/errors'
expressWrap = require 'co-express'
log = require 'winston'
Payment = require '../models/Payment'
Product = require '../models/Product'
User = require '../models/User'

module.exports.setup = (app) ->
  app.post '/paypal/webhook', expressWrap (req, res) ->
    try
      unless req.body.event_type is "PAYMENT.SALE.COMPLETED"
        log.info "PayPal webhook unknown event #{req.body.event_type}"
        return res.status(200).send("PayPal webhook unknown event #{req.body.event_type}")

      payPalPayment = req.body.resource
      unless payPalPayment?.state is 'completed'
        log.error "PayPal webhook payment incomplete state: #{payPalPayment?.id} #{payPalPayment?.state}"
        return res.status(200).send("PayPal webhook payment incomplete state: #{payPalPayment?.id} #{payPalPayment?.state}")

      billingAgreementID = payPalPayment.billing_agreement_id
      user = yield User.findOne({'payPal.billingAgreementID': billingAgreementID})
      unless user
        log.error "PayPal webhook payment no user found: #{payPalPayment.id} #{billingAgreementID}"
        return res.status(200).send("PayPal webhook payment no user found: #{payPalPayment.id} #{billingAgreementID}")

      basicSubProduct = yield Product.findBasicSubscriptionForUser(user)
      productID = basicSubProduct?.get('name')
      unless /basic_subscription/.test(productID)
        log.error "PayPal webhook unexpected sub for user: #{user.id} #{productID}"
        return res.status(200).send("PayPal webhook unexpected sub for user: #{user.id} #{productID}")

      amount = Math.round(parseFloat(payPalPayment.amount.total) * 100)

      # Check for existing payment
      payment = yield Payment.findOne({'payPal.id': payPalPayment.id})
      return res.status(200).send("Payment already recorded for #{payPalPayment.id}") if payment

      payment = new Payment({
        purchaser: user.id
        recipient: user.id
        created: new Date().toISOString()
        service: 'paypal'
        amount
        payPal: payPalPayment
        productID
      })
      yield payment.save()

      return res.status(200).send()
    catch e
      # log.error 'PayPal webhook error:', JSON.stringify(e, null, '\t')
      return res.status(500).send()
