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
  
  get: (req, res) ->
    return res.send([]) unless req.user
    q = Payment.find({recipient:req.user._id})
    q.exec((err, payments) ->
      return @sendDatabaseError(res, err) if err
      res.send(payments)
    )
    
  logPaymentError: (req, msg) ->
    console.warn "Payment Error: #{req.user.get('slug')} (#{req.user._id}): '#{msg}'"

  makeNewInstance: (req) ->
    payment = super(req)
    payment.set 'purchaser', req.user._id
    payment.set 'recipient', req.user._id
    payment.set 'created', new Date().toISOString()
    payment

  post: (req, res, pathName) ->
    if pathName is 'check-stripe-charges'
      return @checkStripeCharges(req, res)
    
    if (not req.user) or req.user.isAnonymous()
      return @sendForbiddenError(res)
    
    appleReceipt = req.body.apple?.rawReceipt
    appleTransactionID = req.body.apple?.transactionID
    appleLocalPrice = req.body.apple?.localPrice
    stripeToken = req.body.stripe?.token
    stripeTimestamp = parseInt(req.body.stripe?.timestamp)
    productID = req.body.productID

    if not (appleReceipt or (stripeTimestamp and productID))
      @logPaymentError(req, "Missing data. Apple? #{!!appleReceipt}. Stripe timestamp? #{!!stripeTimestamp}. Product id? #{!!productID}.")
      return @sendBadInputError(res, 'Need either apple.rawReceipt or stripe.timestamp and productID')

    if stripeTimestamp and not productID
      @logPaymentError(req, 'Missing stripe productID')
      return @sendBadInputError(res, 'Need productID if paying with Stripe.')

    if stripeTimestamp and (not stripeToken) and (not req.user.get('stripe')?.customerID)
      @logPaymentError(req, 'Missing stripe token')
      return @sendBadInputError(res, 'Need stripe.token if new customer.')

    if appleReceipt
      if not appleTransactionID
        @logPaymentError(req, 'Missing apple transaction id')
        return @sendBadInputError(res, 'Apple purchase? Need to specify which transaction.')
      @handleApplePaymentPost(req, res, appleReceipt, appleTransactionID, appleLocalPrice)
      @onPostSuccess req
    else
      @handleStripePaymentPost(req, res, stripeTimestamp, productID, stripeToken)
      @onPostSuccess req

  onPostSuccess: (req) ->
    req.user?.saveActiveUser 'payment'

  #- Apple payments

  handleApplePaymentPost: (req, res, receipt, transactionID, localPrice) ->
    formFields = { 'receipt-data': receipt }

    #- verify receipt with Apple

    verifyReq = request.post({url: config.apple.verifyURL, json: formFields}, (err, verifyRes, body) =>
      if err or not body?.receipt?.in_app or (not body?.bundle_id is 'com.codecombat.CodeCombat')
        console.warn 'apple receipt error?', err, body
        @logPaymentError(req, 'Unable to verify apple receipt')
        @sendBadInputError(res, 'Unable to verify Apple receipt.')
        return

      transaction = _.find body.receipt.in_app, { transaction_id: transactionID }
      unless transaction
        @logPaymentError(req, 'Missing transaction given id.')
        return @sendBadInputError(res, 'Invalid transactionID.')

      #- Check existence
      transactionID = transaction.transaction_id
      criteria = { 'ios.transactionID': transactionID }
      Payment.findOne(criteria).exec((err, payment) =>

        if payment
          unless payment.get('recipient').equals(req.user._id)
            @logPaymentError(req, 'Cross user apple payment.')
            return @sendForbiddenError(res)

          @recalculateGemsFor(req.user, (err) =>
            if err
              @logPaymentError(req, 'Apple recalc db error.'+err)
              return @sendDatabaseError(res, err)
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
        if validation.valid is false
          @logPaymentError(req, 'Invalid apple payment object.')
          return @sendBadInputError(res, validation.errors)
          
        payment.save((err) =>
          if err
            @logPaymentError(req, 'Apple payment save error.'+err)
            return @sendDatabaseError(res, err)
          @incrementGemsFor(req.user, product.gems, (err) =>
            if err
              @logPaymentError(req, 'Apple incr db error.'+err)
              return @sendDatabaseError(res, err)
            @sendPaymentHipChatMessage user: req.user, payment: payment
            @sendCreated(res, @formatEntity(req, payment))
          )
        )
      )
    )


  #- Stripe payments

  handleStripePaymentPost: (req, res, timestamp, productID, token) ->

    # First, make sure we save the payment info as a Customer object, if we haven't already.
    if token
      customerID = req.user.get('stripe')?.customerID
      
      if customerID
        # old customer, new token. Save it.
        stripe.customers.update customerID, { card: token }, (err, customer) =>
          @beginStripePayment(req, res, timestamp, productID)
          
      else
        newCustomer = {
          card: token
          email: req.user.get('email')
          metadata: { id: req.user._id + '', slug: req.user.get('slug') }
        }
        
        stripe.customers.create newCustomer, (err, customer) =>
          if err
            @logPaymentError(req, 'Stripe customer creation error. '+err)
            return @sendDatabaseError(res, err)
          
          stripeInfo = _.cloneDeep(req.user.get('stripe') ? {})
          stripeInfo.customerID = customer.id
          req.user.set('stripe', stripeInfo)
          req.user.save (err) =>
            if err
              @logPaymentError(req, 'Stripe customer id save db error. '+err)
              return @sendDatabaseError(res, err)
            @beginStripePayment(req, res, timestamp, productID)

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
        stripe.charges.list({customer: req.user.get('stripe')?.customerID}, (err, recentCharges) =>
          return callback(err) if err
          charge = _.find recentCharges.data, (c) -> c.metadata.timestamp is timestamp
          callback(null, charge)
        )
      )
    ],

      ((err, results) =>
        if err
          @logPaymentError(req, 'Stripe async load db error. '+err)
          return @sendDatabaseError(res, err) 
        [payment, charge] = results

        if not (payment or charge)
          # Proceed normally from the beginning
          @chargeStripe(req, res, product)

        else if charge and not payment
          # Initialized Payment. Start from charging.
          @recordStripeCharge(req, res, charge)

        else
          # Charged Stripe and recorded it. Recalculate gems to make sure credited the purchase.
          @recalculateGemsFor(req.user, (err) =>
              if err
                @logPaymentError(req, 'Stripe recalc db error. '+err)
                return @sendDatabaseError(res, err)
              @sendPaymentHipChatMessage user: req.user, payment: payment
              @sendSuccess(res, @formatEntity(req, payment))
          )
      )
    )


  chargeStripe: (req, res, product) ->
    stripe.charges.create({
      amount: product.amount
      currency: 'usd'
      customer: req.user.get('stripe')?.customerID
      metadata: {
        productID: product.id
        userID: req.user._id + ''
        gems: product.gems
        timestamp: parseInt(req.body.stripe?.timestamp)
      }
      receipt_email: req.user.get('email')
    }).then(
      # success case
      ((charge) => @recordStripeCharge(req, res, charge)),

      # error case
      ((err) =>
        if err.type in ['StripeCardError', 'StripeInvalidRequestError']
          @sendError(res, 402, err.message)
        else
          @logPaymentError(req, 'Stripe charge error. '+err)
          @sendDatabaseError(res, 'Error charging card, please retry.'))
    )


  recordStripeCharge: (req, res, charge) ->
    return @sendError(res, 500, 'Fake db error for testing.') if req.body.breakAfterCharging
    payment = @makeNewInstance(req)
    payment.set 'service', 'stripe'
    payment.set 'productID', charge.metadata.productID
    payment.set 'amount', parseInt(charge.amount)
    payment.set 'gems', parseInt(charge.metadata.gems)
    payment.set 'stripe', {
      customerID: charge.customer
      timestamp: parseInt(charge.metadata.timestamp)
      chargeID: charge.id
    }
    
    validation = @validateDocumentInput(payment.toObject())
    if validation.valid is false
      @logPaymentError(req, 'Invalid stripe payment object.')
      return @sendBadInputError(res, validation.errors)
    payment.save((err) =>

      # Credit gems
      return @sendDatabaseError(res, err) if err
      @incrementGemsFor(req.user, parseInt(charge.metadata.gems), (err) =>
        if err
          @logPaymentError(req, 'Stripe incr db error. '+err)
          return @sendDatabaseError(res, err)
        @sendCreated(res, @formatEntity(req, payment))
      )
    )

    
  #- Confirm all Stripe charges are recorded on our server
  
  checkStripeCharges: (req, res) ->
    return @sendSuccess(res) unless customerID = req.user.get('stripe')?.customerID
    async.parallel([
        ((callback) ->
          criteria = { recipient: req.user._id, 'stripe.invoiceID': { $exists: false } }
          Payment.find(criteria).limit(100).sort({_id:-1}).exec((err, payments) =>
            callback(err, payments)
          )
        ),
        ((callback) ->
          stripe.charges.list({customer: customerID, limit: 100}, (err, recentCharges) =>
            return callback(err) if err
            callback(null, recentCharges.data)
          )
        )
      ],

      ((err, results) =>
        if err
          @logPaymentError(req, 'Stripe async load db error. '+err)
          return @sendDatabaseError(res, err)

        [payments, charges] = results
        recordedChargeIDs = (p.get('stripe').chargeID for p in payments)
        for charge in charges
          continue if charge.invoice # filter out subscription charges
          if charge.id not in recordedChargeIDs
            return @recordStripeCharge(req, res, charge)

        @sendSuccess(res)
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

  sendPaymentHipChatMessage: (options) ->
    try
      message = "#{options.user?.get('name')} bought #{options.payment?.get('amount')} via #{options.payment?.get('service')}."
      hipchat.sendHipChatMessage message
    catch e
      log.error "Couldn't send HipChat message on payment because of error: #{e}"

module.exports = new PaymentHandler()
