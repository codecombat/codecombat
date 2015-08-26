Handler = require '../commons/Handler'
Prepaid = require './Prepaid'
StripeUtils = require '../lib/stripe_utils'
{getPrepaidCodeAmount} = require '../../app/core/utils'

# TODO: Should this happen on a save() call instead of a prepaid/-/create post?
# TODO: Probably a better way to create a unique 8 charactor string property using db voodoo

PrepaidHandler = class PrepaidHandler extends Handler
  modelClass: Prepaid
  jsonSchema: require '../../app/schemas/models/prepaid.schema'
  allowedMethods: ['POST']

  baseAmount: 999

  logPurchaseError: (user, msg) ->
    console.warn "Prepaid Purchase Error: [#{user.get('slug')} (#{user._id})] '#{msg}'"

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
    return @sendForbiddenError(res) unless req.user?
    return @sendForbiddenError(res) unless req.body.type is 'terminal_subscription'

    maxRedeemers = parseInt(req.body.maxRedeemers)
    months = parseInt(req.body.months)

    return @sendForbiddenError(res) unless isNaN(maxRedeemers) is false and maxRedeemers > 0
    return @sendForbiddenError(res) unless isNaN(months) is false and months > 0
    return @sendError(res, 403, "Users or Months must be greater than 3") if maxRedeemers < 3 and months < 3

    StripeUtils.getCustomer req.user, req.body.stripe?.token, (err, customer) =>
      if err
        @logPurchaseError(req.user, "getCustomer error: #{JSON.stringify(err)}")
        return @sendDatabaseError(res, err)

      metadata =
        type: req.body.type
        userID: req.user._id + ''
        timestamp: parseInt(req.body.stripe?.timestamp)
        description: req.body.description
        maxRedeemers: maxRedeemers
        months: months
        productID: 'prepaid ' + req.body.type

      amount = getPrepaidCodeAmount(@baseAmount, maxRedeemers, months)

      StripeUtils.createCharge req.user, amount, metadata, (err, charge) =>
        if err
          @logPurchaseError(req.user, "createCharge error: #{JSON.stringify(err)}")
          return @sendDatabaseError(res, err)

        StripeUtils.createPayment req.user, charge, (err, payment) =>
          if err
            @logPurchaseError(req.user, "createPayment error: #{JSON.stringify(err)}")
            return @sendDatabaseError(res, err)

          Prepaid.generateNewCode (code) =>
            return @sendDatabaseError(res, 'Database error.') unless code
            prepaid = new Prepaid
              creator: req.user.id
              type: req.body.type
              code: code
              maxRedeemers: req.body.maxRedeemers
              properties:
                months: req.body.months
            prepaid.save (err) =>
              return @sendDatabaseError(res, err) if err
              @sendSuccess(res, prepaid.toObject())

module.exports = new PrepaidHandler()
