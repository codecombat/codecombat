log = require 'winston'
Payment = require '../models/Payment'
Promise = require 'bluebird'
config = require '../../server_config'
errors = require '../commons/errors'

module.exports =
  api: require('stripe')(config.stripe.secretKey)
  
  logError: (user, msg) ->
    log.error "Stripe Utils Error: #{user.get('slug')} (#{user._id}): '#{msg}'"

  createCharge: (user, amount, metadata, done) ->
    # TODO: create Stripe customer if necessary
    options =
      amount: amount
      currency: 'usd'
      customer: user.get('stripe')?.customerID
      metadata: metadata
      receipt_email: user.get('email')
      statement_descriptor: 'CODECOMBAT.COM'
    stripe.charges.create options, (err, charge) =>
      if err
        if err?.message.indexOf('declined')
          return done(new errors.PaymentRequired('Card declined'))
        @logError(user, "Charge create error: #{JSON.stringify(err)}")
        return done(err)
      done(err, charge)

  createPayment: (user, stripeCharge, extraProps, done) ->
    PaymentHandler = require '../handlers/payment_handler' # require JIT so server models can initialize properly first
    payment = new Payment
      purchaser: user._id
      recipient: user._id
      created: new Date().toISOString()
      service: 'stripe'
      amount: parseInt(stripeCharge.amount)
    payment.set 'description', stripeCharge.metadata.description if stripeCharge.metadata.description
    payment.set 'gems', parseInt(stripeCharge.metadata.gems) if stripeCharge.metadata.gems
    payment.set 'stripe',
      customerID: stripeCharge.customer
      timestamp: parseInt(stripeCharge.metadata.timestamp)
      chargeID: stripeCharge.id
    payment.set(prop, val) for prop, val of extraProps
    validation = PaymentHandler.validateDocumentInput(payment.toObject())
    if validation.valid is false
      @logError(user, 'Invalid stripe payment object.')
      return done(validation.errors)
    payment.save (err) =>
      if err
        @logError(user, "Payment save error: #{JSON.stringify(err)}")
        return done(err)
      done(err, payment)

  getCustomer: (user, token, done) ->
    # If necessary, creates new Stripe customer and saves to user
    customerID = user.get('stripe')?.customerID
    if customerID
      if token
        # old customer, new token. Save it.
        stripe.customers.update customerID, { card: token }, (err, customer) =>
          if err
            @logError(user, "Customer update error: #{JSON.stringify(err)}")
            return done(err)
          done(err, customer)
      else
        stripe.customers.retrieve customerID, (err, customer) =>
          if err
            @logError(user, "Customer retrieve error: #{JSON.stringify(err)}")
            return done(err)
          done(err, customer)
    else if token
      newCustomer = {
        card: token
        email: user.get('email')
        metadata: { id: user._id + '', slug: user.get('slug') }
      }
      stripe.customers.create newCustomer, (err, customer) =>
        if err
          @logError(user, "Customer creation error: #{JSON.stringify(err)}")
          return done(err)
        stripeInfo = _.cloneDeep(user.get('stripe') ? {})
        stripeInfo.customerID = customer.id
        user.set('stripe', stripeInfo)
        user.save (err) =>
          if err
            @logError(user, 'Stripe customer id save db error. '+err)
            return done(err)
          done(err, customer)
    else
      done(null, null)

  cancelSubscriptionImmediately: (user, subscription, done) ->
    return done() unless user and subscription
    stripe.customers.cancelSubscription subscription.customer, subscription.id, (err) ->
      return done(err) if err
      stripeInfo = _.cloneDeep(user.get('stripe') ? {})
      delete stripeInfo.planID
      delete stripeInfo.prepaidCode
      delete stripeInfo.subscriptionID
      user.set('stripe', stripeInfo)
      user.save(done)

Promise.promisifyAll(module.exports)
