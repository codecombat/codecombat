log = require 'winston'
Payment = require '../models/Payment'
PaymentHandler = require '../handlers/payment_handler'

module.exports =
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
        @logError(user, "Charge create error: #{JSON.stringify(err)}")
        return done(err)
      done(err, charge)

  createPayment: (user, stripeCharge, extraProps, done) ->
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
    else
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
