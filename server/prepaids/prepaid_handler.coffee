Handler = require '../commons/Handler'
Prepaid = require './Prepaid'
Payment = require '../payments/Payment'
PaymentHandler = require '../payments/payment_handler'
async = require 'async'

products =
  'custom':
    id: 'custom'

# TODO: Should this happen on a save() call instead of a prepaid/-/create post?
# TODO: Probably a better way to create a unique 8 charactor string property using db voodoo

PrepaidHandler = class PrepaidHandler extends Handler
  modelClass: Prepaid
  jsonSchema: require '../../app/schemas/models/prepaid.schema'
  allowedMethods: ['POST']

  hasAccess: (req) ->
    req.user?.isAdmin()

  getByRelationship: (req, res, args...) ->
    relationship = args[1]
    return @createPrepaid(req, res) if relationship is 'create'
    return @purchasePrepaid(req, res) if relationship is 'purchase'
    super arguments...

  createPrepaid: (req, res) ->
    return @sendForbiddenError(res) unless @hasAccess(req)
    return @sendForbiddenError(res) unless req.body.type is 'subscription'
    return @sendForbiddenError(res) unless req.body.maxRedeemers > 0
    Prepaid.generateNewCode (code) =>
      return @sendDatabaseError(res, 'Database error.') unless code
      prepaid = new Prepaid
        creator: req.user.id
        type: req.body.type
        code: code
        maxRedeemers: req.body.maxRedeemers
        properties:
          couponID: 'free'
      prepaid.save (err) =>
        return @sendDatabaseError(res, err) if err
        @sendSuccess(res, prepaid.toObject())

  purchasePrepaid: (req, res) ->
    return @sendForbiddenError(res) unless req.body.type is 'terminal_subscription'
    return @sendError(res, 400, "Users or Months must be greater than 3") if req.body.maxRedeemers < 3 and req.body.months < 3

    stripeTimestamp = parseInt(req.body.stripe?.timestamp)
    stripeToken = req.body.stripe?.token

    @handleStripePaymentPost(req, res, stripeTimestamp, 'custom', stripeToken)

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
          return @sendSuccess(res, @formatEntity(req, payment)) if product.id is 'custom'

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
    amount = parseInt product.amount ? req.body.amount
    return @sendError(res, 400, "Invalid amount.") if isNaN(amount)

    stripe.charges.create({
      amount: amount
      currency: 'usd'
      customer: req.user.get('stripe')?.customerID
      metadata: {
        productID: product.id
        userID: req.user._id + ''
        gems: product.gems
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

    payment = PaymentHandler.makeNewInstance(req)
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

    validation = PaymentHandler.validateDocumentInput(payment.toObject())
    if validation.valid is false
      PaymentHandler.logPaymentError(req, 'Invalid stripe payment object.')
      return @sendBadInputError(res, validation.errors)
    payment.save((err, payment) =>
      return @sendDatabaseError(res, err) if err
      @makeNewPrepaidCode(req, res)
    )

  makeNewPrepaidCode: (req, res) =>
    Prepaid.generateNewCode (code) =>
      return @sendDatabaseError(res, 'Database error.') unless code
      prepaid = new Prepaid
        creator: req.user.id
        type: req.body.type
        code: code
        maxRedeemers: req.body.maxRedeemers
        properties:
          couponID: 'free'
          months: req.body.months
      prepaid.save (err) =>
        return @sendDatabaseError(res, err) if err
        @sendSuccess(res, prepaid.toObject())

module.exports = new PrepaidHandler()
