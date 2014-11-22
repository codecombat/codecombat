Payment = require './Payment'
User = require '../users/User'
Handler = require '../commons/Handler'
{handlers} = require '../commons/mapping'
mongoose = require 'mongoose'
log = require 'winston'
sendwithus = require '../sendwithus'
hipchat = require '../hipchat'
config = require '../../server_config'
request = require 'request'
stripe = require('stripe')(config.stripe.secretKey)
async = require 'async'

products = {
  'gems_5': {
    amount: 499
    gems: 5000
    id: 'gems_5'
  }
  
  'gems_10': {
    amount: 999
    gems: 11000
    id: 'gems_10'
  }
  
  'gems_20': {
    amount: 1999
    gems: 25000
    id: 'gems_20'
  }
}

PaymentHandler = class PaymentHandler extends Handler
  modelClass: Payment
  editableProperties: []
  postEditableProperties: ['purchased']
  jsonSchema: require '../../app/schemas/models/payment.schema'

  makeNewInstance: (req) ->
    payment = super(req)
    payment.set 'purchaser', req.user._id
    payment.set 'recipient', req.user._id
    payment.set 'created', new Date().toISOString()
    payment
    
  post: (req, res) ->
    appleReceipt = req.body.apple?.rawReceipt
    appleTransactionID = req.body.apple?.transactionID
    appleLocalPrice = req.body.apple?.localPrice
    stripeToken = req.body.stripe?.token
    stripeTimestamp = parseInt(req.body.stripe?.timestamp)
    productID = req.body.productID
    
    if not (appleReceipt or (stripeTimestamp and productID))
      return @sendBadInputError(res, 'Need either apple.rawReceipt or stripe.timestamp and productID')
      
    if stripeTimestamp and not productID
      return @sendBadInputError(res, 'Need productID if paying with Stripe.')

    if stripeTimestamp and (not stripeToken) and (not user.get('stripeCustomerID'))
      return @sendBadInputError(res, 'Need stripe.token if new customer.')
      
    if appleReceipt
      if not appleTransactionID
        return @sendBadInputError(res, 'Apple purchase? Need to specify which transaction.')
      @handleApplePaymentPost(req, res, appleReceipt, appleTransactionID, appleLocalPrice)
      
    else
      @handleStripePaymentPost(req, res, stripeTimestamp, productID, stripeToken)
      
      
  #- Apple payments
      
  handleApplePaymentPost: (req, res, receipt, transactionID, localPrice) ->
    formFields = { 'receipt-data': receipt }
    
    #- verify receipt with Apple 
    
    verifyReq = request.post({url: config.apple.verifyURL, json: formFields}, (err, verifyRes, body) =>
      if err or not body?.receipt?.in_app or (not body?.bundle_id is 'com.codecombat.CodeCombat')
        console.warn 'apple receipt error?', err, body
        @sendBadInputError(res, 'Unable to verify Apple receipt.')
        return
      
      transaction = _.find body.receipt.in_app, { transaction_id: transactionID }
      return @sendBadInputError(res, 'Invalid transactionID.') unless transaction 
        
      #- Check existence
      transactionID = transaction.transaction_id
      criteria = { 'ios.transactionID': transactionID }
      Payment.findOne(criteria).exec((err, payment) =>
        
        if payment
          unless payment.get('recipient').equals(req.user._id)
            return @sendForbiddenError(res)

          @recalculateGemsFor(req.user, (err) =>
            return @sendDatabaseError(res, err) if err
            @sendSuccess(res, @formatEntity(req, payment))
          )
          return

        payment = @makeNewInstance(req)
        payment.set 'service', 'ios'
        product = products[transaction.product_id]

        payment.set 'amount', product.amount
        payment.set 'gems', product.gems
        payment.set 'ios', {
          transactionID: transactionID
          rawReceipt: receipt
          localPrice: localPrice
        }

        validation = @validateDocumentInput(payment.toObject())
        return @sendBadInputError(res, validation.errors) if validation.valid is false
        payment.save((err) =>
          return @sendDatabaseError(res, err) if err
          @incrementGemsFor(req.user, product.gems, (err) =>
            return @sendDatabaseError(res, err) if err
            @sendCreated(res, @formatEntity(req, payment))
          )
        )
      )
    )

    
  #- Stripe payments
    
  handleStripePaymentPost: (req, res, timestamp, productID, token) ->
    
    # First, make sure we save the payment info as a Customer object, if we haven't already.
    if not req.user.get('stripeCustomerID')
      stripe.customers.create({
        card: token
        description: req.user._id + ''
      }).then(((customer) =>
        req.user.set('stripeCustomerID', customer.id)
        req.user.save((err) =>
          return @sendDatabaseError(res, err) if err
          @beginStripePayment(req, res, timestamp, productID)
        )
        ),
        (err) =>
          return @sendDatabaseError(res, err)
      )
    
    else
      @beginStripePayment(req, res, timestamp, productID)
      

  beginStripePayment: (req, res, timestamp, productID) ->
    product = products[productID]

    async.parallel([
      ((callback) ->
        criteria = { recipient: req.user._id, 'stripe.timestamp': timestamp }
        Payment.findOne(criteria).exec((err, payment) =>
          callback(err, payment)
        )
      ),
      ((callback) ->
        stripe.charges.list({customer: req.user.get('stripeCustomerID')}, (err, recentCharges) =>
          return callback(err) if err
          charge = _.find recentCharges.data, (c) -> c.metadata.timestamp is timestamp
          callback(null, charge)
        )
      )
    ],
      
      ((err, results) =>
        return @sendDatabaseError(res, err) if err 
        [payment, charge] = results
  
        if not (payment or charge)
          # Proceed normally from the beginning
          @chargeStripe(req, res, payment, product)
            
        else if charge and not payment
          # Initialized Payment. Start from charging.
          @recordStripeCharge(req, res, payment, product, charge)
  
        else
          # Charged Stripe and recorded it. Recalculate gems to make sure credited the purchase.
          @recalculateGemsFor(req.user, (err) =>
              return @sendDatabaseError(res, err) if err
              @sendSuccess(res, @formatEntity(req, payment))
          )
      )
    )

    
  chargeStripe: (req, res, payment, product) ->
    stripe.charges.create({
      amount: product.amount
      currency: 'usd'
      customer: req.user.get('stripeCustomerID')
      metadata: {
        productID: product.id
        userID: req.user._id + ''
        gems: product.gems
        timestamp: parseInt(req.body.stripe?.timestamp)
      }
      receipt_email: req.user.get('email')
    }).then(
      # success case
      ((charge) => @recordStripeCharge(req, res, payment, product, charge)),
      
      # error case
      ((err) =>
        if err.type in ['StripeCardError', 'StripeInvalidRequestError']
          @sendError(res, 402, err.message)
        else
          @sendDatabaseError(res, 'Error charging card, please retry.'))
    )
    
    
  recordStripeCharge: (req, res, payment, product, charge) ->
    return @sendError(res, 500, 'Fake db error for testing.') if req.body.breakAfterCharging
    payment = @makeNewInstance(req)
    payment.set 'service', 'stripe'
    payment.set 'productID', req.body.productID
    payment.set 'amount', product.amount
    payment.set 'gems', product.gems
    payment.set 'stripe', {
      customerID: req.user.get('stripeCustomerID')
      timestamp: parseInt(req.body.stripe.timestamp)
      chargeID: charge.id
    }

    validation = @validateDocumentInput(payment.toObject())
    return @sendBadInputError(res, validation.errors) if validation.valid is false
    payment.save((err) =>

      # Credit gems
      return @sendDatabaseError(res, err) if err
      @incrementGemsFor(req.user, product.gems, (err) =>
        return @sendDatabaseError(res, err) if err
        @sendCreated(res, @formatEntity(req, payment))
      )
    )

    
  #- Incrementing/recalculating gems
    
  incrementGemsFor: (user, gems, done) ->
    purchased = _.clone(user.get('purchased'))
    if not purchased?.gems
      purchased ?= {}
      purchased.gems = gems
      user.set('purchased', purchased)
      user.save((err) -> done(err))
      
    else
      user.update({$inc: {'purchased.gems': gems}}, {}, (err) -> done(err))
      
  recalculateGemsFor: (user, done) ->

    Payment.find({recipient: user._id}).select('gems').exec((err, payments) ->
      gems = _.reduce payments, ((sum, p) -> sum + p.get('gems')), 0
      purchased = _.clone(user.get('purchased'))
      purchased ?= {}
      purchased.gems = gems
      user.set('purchased', purchased)
      user.save((err) -> done(err))
      
    )
    
module.exports = new PaymentHandler()
