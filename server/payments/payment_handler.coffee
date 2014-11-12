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

products = {
  'gems_5': {
    amount: 500
    gems: 5000
  }
  
  'gems_10': {
    amount: 1000
    gems: 11000
  }
  
  'gems_20': {
    amount: 2000
    gems: 25000
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
    
    if not (appleReceipt or stripeTimestamp)
      return @sendBadInputError(res, 'Need either apple.rawReceipt or stripe.timestamp')
      
    if appleReceipt
      if not appleTransactionID
        return @sendBadInputError(res, 'Apple purchase? Need to specify which transaction.')
      @handleApplePaymentPost(req, res, appleReceipt, appleTransactionID, appleLocalPrice)
      
    else
      @handleStripePaymentPost(req, res, stripeTimestamp, stripeToken)
      
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
      criteria = { recipient: req.user._id, 'ios.transactionID': transactionID }
      Payment.findOne(criteria).exec((err, payment) =>
        
        if payment
          @recalculateGemsFor(req.user, (err) =>
            return @sendDatabaseError(res, err) if err
            @sendSuccess(res, @formatEntity(req, payment))
          )
          return

        payment = @makeNewInstance(req)
        payment.set 'service', 'ios'
        product = products[transaction.product_id]

        product ?= _.values(products)[0] # TEST 

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

    
  handleStripePaymentPost: (req, res, timestamp, token) ->
    console.log 'lol not implemented yet'
    @sendNotFoundError(res)
    
    
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
