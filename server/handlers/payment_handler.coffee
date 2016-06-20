Payment = require './../models/Payment'
Prepaid = require '../models/Prepaid'
Product = require '../models/Product'
User = require '../models/User'
Handler = require '../commons/Handler'
{handlers} = require '../commons/mapping'
mongoose = require 'mongoose'
log = require 'winston'
sendwithus = require '../sendwithus'
slack = require '../slack'
config = require '../../server_config'
request = require 'request'
async = require 'async'
apple_utils = require '../lib/apple_utils'


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

  getByRelationship: (req, res, args...) ->
    relationship = args[1]
    return @getSchoolSalesAPI(req, res) if relationship is 'school_sales'
    super arguments...

  logPaymentError: (req, msg) ->
    log.warn "Payment Error: #{req.user.get('slug')} (#{req.user._id}): '#{msg}'"

  makeNewInstance: (req) ->
    payment = super(req)
    payment.set 'purchaser', req.user._id
    payment.set 'recipient', req.user._id
    payment.set 'created', new Date().toISOString()
    payment

  getSchoolSalesAPI: (req, res, code) ->
    return @sendUnauthorizedError(res) unless req.user?.isAdmin()
    userIDs = [];
    Payment.find({}, {amount: 1, created: 1, description: 1, prepaidID: 1, productID: 1, purchaser: 1, service: 1}).exec (err, payments) =>
      return @sendDatabaseError(res, err) if err
      schoolSales = []
      prepaidIDs = []
      prepaidPaymentMap = {}
      for payment in payments
        continue unless payment.get('amount')? and payment.get('amount') > 0
        unless created = payment.get('created')
          created = payment.get('_id').getTimestamp()
        description = payment.get('description') ? ''
        if prepaidID = payment.get('prepaidID')
          unless prepaidPaymentMap[prepaidID.valueOf()]
            prepaidPaymentMap[prepaidID.valueOf()] = {_id: payment.get('_id').valueOf(), amount: payment.get('amount'), created: created, description: description, userID: payment.get('purchaser').valueOf(), prepaidID: prepaidID.valueOf()}
            prepaidIDs.push(prepaidID)
            userIDs.push(payment.get('purchaser'))
        else if payment.get('productID') is 'custom' or payment.get('service') is 'external' or payment.get('service') is 'invoice'
          schoolSales.push({_id: payment.get('_id').valueOf(), amount: payment.get('amount'), created: created, description: description, userID: payment.get('purchaser').valueOf()})
          userIDs.push(payment.get('purchaser'))

      Prepaid.find({$and: [{_id: {$in: prepaidIDs}}, {type: 'course'}]}, {_id: 1}).exec (err, prepaids) =>
        return @sendDatabaseError(res, err) if err
        for prepaid in prepaids
          schoolSales.push(prepaidPaymentMap[prepaid.get('_id').valueOf()])

        User.find({_id: {$in: userIDs}}).exec (err, users) =>
          return @sendDatabaseError(res, err) if err
          userMap = {}
          for user in users
            userMap[user.get('_id').valueOf()] = user
          for schoolSale in schoolSales
            schoolSale.user = userMap[schoolSale.userID]?.toObject()

          @sendSuccess(res, schoolSales)

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

    if pathName is 'custom'
      return @handleStripePaymentPost(req, res, stripeTimestamp, 'custom', stripeToken)

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
    else
      @handleStripePaymentPost(req, res, stripeTimestamp, productID, stripeToken)

  #- Apple payments

  handleApplePaymentPost: (req, res, receipt, transactionID, localPrice) ->
    #- verify receipt with Apple

    apple_utils.verifyReceipt(receipt, (err, body) =>
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
        Product.findOne({name: transaction.product_id}).exec (err, product) =>
          return @sendDatabaseError(res, err) if err
          return @sendNotFoundError(res) if not product
          payment.set 'amount', product.get('amount')
          payment.set 'gems', product.get('gems')
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
            @incrementGemsFor(req.user, product.get('gems'), (err) =>
              if err
                @logPaymentError(req, 'Apple incr db error.'+err)
                return @sendDatabaseError(res, err)
              @sendPaymentSlackMessage user: req.user, payment: payment
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
      ),
      ((callback) ->
        Product.findOne({name: productID}).exec (err, product) =>
          callback(err, product)
      )
    ],

      ((err, results) =>
        if err
          @logPaymentError(req, 'Stripe async load db error. '+err)
          return @sendDatabaseError(res, err)
        [payment, charge, product] = results

        if not product
          return @sendNotFoundError(res, 'could not find product with id '+productID)

        if not (payment or charge)
          # Proceed normally from the beginning
          @chargeStripe(req, res, product)

        else if charge and not payment
          # Initialized Payment. Start from charging.
          @recordStripeCharge(req, res, charge)

        else
          return @sendSuccess(res, @formatEntity(req, payment)) if product.get('name') is 'custom'

          # Charged Stripe and recorded it. Recalculate gems to make sure credited the purchase.
          @recalculateGemsFor(req.user, (err) =>
              if err
                @logPaymentError(req, 'Stripe recalc db error. '+err)
                return @sendDatabaseError(res, err)
              @sendPaymentSlackMessage user: req.user, payment: payment
              @sendSuccess(res, @formatEntity(req, payment))
          )
      )
    )

  chargeStripe: (req, res, product) ->
    amount = parseInt product.get('amount') ? req.body.amount
    return @sendError(res, 400, "Invalid amount.") if isNaN(amount)

    stripe.charges.create({
      amount: amount
      currency: 'usd'
      customer: req.user.get('stripe')?.customerID
      metadata: {
        productID: product.get('name')
        userID: req.user._id + ''
        gems: product.get('gems')
        timestamp: parseInt(req.body.stripe?.timestamp)
        description: req.body.description
      }
      receipt_email: req.user.get('email')
      statement_descriptor: 'CODECOMBAT.COM'
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
    payment.set 'gems', parseInt(charge.metadata.gems) if charge.metadata.gems
    payment.set 'description', charge.metadata.description if charge.metadata.description
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
      return @sendDatabaseError(res, err) if err
      return @sendCreated(res, @formatEntity(req, payment)) if payment.productID is 'custom'

      # Credit gems
      @incrementGemsFor(req.user, parseInt(charge.metadata.gems), (err) =>
        if err
          @logPaymentError(req, 'Stripe incr db error. '+err)
          return @sendDatabaseError(res, err)
        @sendPaymentSlackMessage user: req.user, payment: payment
        @sendCreated(res, @formatEntity(req, payment))
      )
    )

  #- Confirm all Stripe charges are recorded on our server

  checkStripeCharges: (req, res) ->
    return @sendSuccess(res) unless customerID = req.user.get('stripe')?.customerID
    async.parallel([
        ((callback) ->
          criteria = { recipient: req.user._id, 'stripe.invoiceID': { $exists: false }, 'ios.transactionID': { $exists: false } }
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
          continue unless charge.paid
          continue if charge.invoice # filter out subscription charges
          if charge.id not in recordedChargeIDs
            return @recordStripeCharge(req, res, charge)

        @sendSuccess(res)
      )
    )

  #- Incrementing/recalculating gems

  incrementGemsFor: (user, gems, done) ->
    if not gems
      return done()
      
    purchased = _.clone(user.get('purchased'))
    if not purchased?.gems
      purchased ?= {}
      purchased.gems = gems
      user.set('purchased', purchased)
      user.save((err) -> done(err))

    else
      user.update({$inc: {'purchased.gems': gems}}, {}, (err) -> done(err))

  recalculateGemsFor: (user, done, saveIfUnchanged=true) ->

    Payment.find({recipient: user._id}).select('gems').exec((err, payments) ->
      gems = _.reduce payments, ((sum, p) -> sum + p.get('gems')), 0
      purchased = _.clone(user.get('purchased'))
      purchased ?= {}
      if (purchased.gems or 0) isnt gems
        log.debug "Updating #{user.get('_id')} gems from #{purchased.gems} to #{gems} from #{payments.length} payments; #{user.get('email')} #{user.get('name')}"
      else unless saveIfUnchanged
        log.debug "#{user.get('_id')} already had #{purchased.gems} #{gems} from #{payments.length} payments; #{user.get('email')} #{user.get('name')}"
        return done()
      purchased.gems = gems
      user.set('purchased', purchased)
      user.save((err) -> done(err))
    )

  sendPaymentSlackMessage: (options) ->
    try
      message = "#{options.user?.get('emailLower')} paid #{options.payment?.get('amount')} for #{options.payment.get('description') or '???, no payment description!'}"
      slack.sendSlackMessage message, ['tower']
    catch e
      log.error "Couldn't send Slack message on payment because of error: #{e}"

module.exports = new PaymentHandler()
