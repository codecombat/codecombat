errors = require '../commons/errors'
co = require 'co'
expressWrap = require 'co-express'
log = require 'winston'
mongoose = require 'mongoose'
paypal = require '../lib/paypal'
Payment = require '../models/Payment'
Product = require '../models/Product'
User = require '../models/User'

module.exports.setup = (app) ->
  app.post '/paypal/webhook', expressWrap (req, res) ->
    try
      if req.body.event_type is "PAYMENT.SALE.COMPLETED"
        log.info "PayPal webhook event #{req.body.event_type} received"
        yield handlePaymentSucceeded(req, res)
      else if req.body.event_type is "BILLING.SUBSCRIPTION.CANCELLED"
        log.info "PayPal webhook event #{req.body.event_type} received"
        yield handleSubscriptionCancelled(req, res)
      else
        log.info "PayPal webhook unknown event #{req.body.event_type}"
        return res.status(200).send("PayPal webhook unknown event #{req.body.event_type}")
    catch e
      log.error 'PayPal webhook error:', JSON.stringify(e, null, '\t')
      return res.status(500).send()

  handlePaymentSucceeded = co.wrap (req, res) ->
    payPalSalePayment = req.body.resource
    unless payPalSalePayment?.state is 'completed'
      log.error "PayPal webhook payment incomplete state: #{payPalSalePayment?.id} #{payPalSalePayment?.state}"
      return res.status(200).send("PayPal webhook payment incomplete state: #{payPalSalePayment?.id} #{payPalSalePayment?.state}")

    if payPalSalePayment.billing_agreement_id
      return yield handleBillingAgreementPaymentSucceeded(req, res, payPalSalePayment)
    else if payPalSalePayment.parent_payment
      # One-time full payments not handled here (e.g. lifetime subscriptions)
      return res.status(200).send()

    log.warning "PayPal webhook unrecognized sale payment #{JSON.stringify(payPalSalePayment)}"
    return res.status(200).send("PayPal webhook unrecognized sale payment #{JSON.stringify(payPalSalePayment)}")

  handleBillingAgreementPaymentSucceeded = co.wrap (req, res, payPalSalePayment) ->
    # Recurring purchases (e.g. monthly subs)
    # No full payments via parent_payment property
    # Assumes only called for basic_subscription product currently

    # Check for existing payment
    payment = yield Payment.findOne({'payPalSale.id': payPalSalePayment.id})
    return res.status(200).send("Payment already recorded for #{payPalSalePayment.id}") if payment

    billingAgreementID = payPalSalePayment.billing_agreement_id

    # Check for initial subscribe payment and add sale object
    payment = yield Payment.findOne({'payPalBillingAgreementID': billingAgreementID, 'payPalSale': {$exists: false}})
    if payment
      payment.set('payPalSale', payPalSalePayment)
      yield payment.save()
      return res.status(200).send("Payment sale object #{payPalSalePayment.id} added to initial payment #{payment.id}")

    user = yield User.findOne({'payPal.billingAgreementID': billingAgreementID})
    unless user
      log.error "PayPal webhook payment no user found: #{payPalSalePayment.id} #{billingAgreementID}"
      return res.status(200).send("PayPal webhook payment no user found: #{payPalSalePayment.id} #{billingAgreementID}")

    basicSubProduct = yield Product.findBasicSubscriptionForUser(user)
    productID = basicSubProduct?.get('name')
    unless /basic_subscription/.test(productID)
      log.error "PayPal webhook unexpected sub for user: #{user.id} #{productID}"
      return res.status(200).send("PayPal webhook unexpected sub for user: #{user.id} #{productID}")

    amount = Math.round(parseFloat(payPalSalePayment.amount.total) * 100)
    gems = basicSubProduct.get('gems')

    payment = new Payment({
      purchaser: user.get('_id')
      recipient: user.get('_id')
      created: new Date().toISOString()
      service: 'paypal'
      amount
      gems
      payPalSale: payPalSalePayment
      productID
    })
    yield payment.save()

    # Add gems to User
    purchased = _.cloneDeep(user.get('purchased') ? {})
    purchased.gems ?= 0
    purchased.gems += gems if gems
    user.set('purchased', purchased)
    yield user.save()

    return res.status(200).send()


  handleSubscriptionCancelled = co.wrap (req, res) ->
    billingAgreement = req.body?.resource
    unless billingAgreement
      log.error("PayPal webhook subscription cancellation, no billing agreement given for #{req.body.event_type} #{JSON.stringify(req.body)}")
      return res.status(200).send("PayPal webhook subscription cancellation, no billing agreement given for #{req.body.event_type} #{JSON.stringify(req.body)}")

    billingAgreementID = billingAgreement.id
    user = yield User.findOne({'payPal.billingAgreementID': billingAgreementID})
    unless user
      log.error("PayPal webhook subscription cancellation, no billing agreement for #{billingAgreementID}")
      return res.status(200).send("PayPal webhook subscription cancellation, no billing agreement for #{billingAgreementID}")

    yield user.cancelPayPalSubscription()

    return res.status(200).send()
