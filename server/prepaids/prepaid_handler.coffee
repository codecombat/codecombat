Course = require '../courses/Course'
Handler = require '../commons/Handler'
hipchat = require '../hipchat'
Prepaid = require './Prepaid'
User = require '../users/User'
StripeUtils = require '../lib/stripe_utils'
utils = require '../../app/core/utils'
mongoose = require 'mongoose'
Product = require '../models/Product'

# TODO: Should this happen on a save() call instead of a prepaid/-/create post?
# TODO: Probably a better way to create a unique 8 charactor string property using db voodoo

cutoffID = mongoose.Types.ObjectId('5642877accc6494a01cc6bfe')

PrepaidHandler = class PrepaidHandler extends Handler
  modelClass: Prepaid
  jsonSchema: require '../../app/schemas/models/prepaid.schema'
  allowedMethods: ['GET','POST']

  logError: (user, msg) ->
    console.warn "Prepaid Error: [#{user.get('slug')} (#{user._id})] '#{msg}'"

  hasAccess: (req) ->
    req.method is 'GET' || req.user?.isAdmin()

  getByRelationship: (req, res, args...) ->
    relationship = args[1]
    return @getPrepaidAPI(req, res, args[2]) if relationship is 'code'
    return @createPrepaidAPI(req, res) if relationship is 'create'
    return @purchasePrepaidAPI(req, res) if relationship is 'purchase'
    return @postRedeemerAPI(req, res, args[0]) if relationship is 'redeemers'
    super arguments...

  getPrepaidAPI: (req, res, code) ->
    return @sendForbiddenError(res) unless req.user?
    return @sendNotFoundError(res, "You must specify a code") unless code

    Prepaid.findOne({ code: code.toString() }).exec (err, prepaid) =>
      if err
        console.warn "Get Prepaid Code Error [#{req.user.get('slug')} (#{req.user.id})]: #{JSON.stringify(err)}"
        return @sendDatabaseError(res, err)

      return @sendNotFoundError(res, "Code not found") unless prepaid

      @sendSuccess(res, prepaid.toObject())

  createPrepaidAPI: (req, res) ->
    return @sendForbiddenError(res) unless @hasAccess(req)
    return @sendForbiddenError(res) unless req.body.type in ['course', 'subscription','terminal_subscription']
    return @sendForbiddenError(res) unless parseInt(req.body.maxRedeemers) > 0

    properties = {}
    type = req.body.type
    maxRedeemers = req.body.maxRedeemers

    if req.body.type is 'course'
      return @sendDatabaseError(res, "TODO: need to add courseIDs")
    else if req.body.type is 'subscription'
      properties.couponID = 'free'
    else if req.body.type is 'terminal_subscription'
      properties.months = req.body.months

    @createPrepaid req.user, req.body.type, req.body.maxRedeemers, properties, (err, prepaid) =>
      return @sendDatabaseError(res, err) if err
      @sendSuccess(res, prepaid.toObject())

  postRedeemerAPI: (req, res, prepaidID) ->
    return @sendForbiddenError(res) if prepaidID.toString() < cutoffID.toString()
    return @sendMethodNotAllowed(res, 'You may only POST redeemers.') if req.method isnt 'POST'
    return @sendBadInputError(res, 'Need an object with a userID') unless req.body?.userID
    Prepaid.findById(prepaidID).exec (err, prepaid) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) if not prepaid
      return @sendForbiddenError(res) if prepaid.get('creator').toString() isnt req.user.id
      return @sendForbiddenError(res) if prepaid.get('redeemers')? and _.size(prepaid.get('redeemers')) >= prepaid.get('maxRedeemers')
      return @sendForbiddenError(res) unless prepaid.get('type') is 'course'
      return @sendForbiddenError(res) if prepaid.get('properties')?.endDate < new Date()
      User.findById(req.body.userID).exec (err, user) =>
        return @sendDatabaseError(res, err) if err
        return @sendNotFoundError(res, 'User for given ID not found') if not user
        return @sendSuccess(res, @formatEntity(req, prepaid)) if user.get('coursePrepaidID')
        userID = user.get('_id')

        query =
          _id: prepaid.get('_id')
          'redeemers.userID': { $ne: user.get('_id') }
          $where: "this.maxRedeemers > 0 && (!this.redeemers || this.redeemers.length < #{prepaid.get('maxRedeemers')})"
        update = { $push: { redeemers : { date: new Date(), userID: userID } }}
        Prepaid.update query, update, (err, result) =>
          return @sendDatabaseError(res, err) if err
          if result.nModified is 0
            @logError(req.user, "POST prepaid redeemer lost race on maxRedeemers")
            return @sendForbiddenError(res)

          user.set('coursePrepaidID', prepaid.get('_id'))
          user.save (err, user) =>
            return @sendDatabaseError(res, err) if err
            # return prepaid with new redeemer added locally
            redeemers = _.clone(prepaid.get('redeemers') or [])
            redeemers.push({ date: new Date(), userID: userID })
            prepaid.set('redeemers', redeemers)
            @sendSuccess(res, @formatEntity(req, prepaid))

  createPrepaid: (user, type, maxRedeemers, properties, done) ->
    Prepaid.generateNewCode (code) =>
      return done('Database error.') unless code
      options =
        creator: user._id
        type: type
        code: code
        maxRedeemers: parseInt(maxRedeemers)
        properties: properties
        redeemers: []

      prepaid = new Prepaid options
      prepaid.save (err) =>
        return done(err) if err
        done(err, prepaid)

  purchasePrepaidAPI: (req, res) ->
    return @sendUnauthorizedError(res) if not req.user? or req.user?.isAnonymous()
    return @sendForbiddenError(res) unless req.body.type in ['course', 'terminal_subscription']

    if req.body.type is 'terminal_subscription'
      description = req.body.description
      maxRedeemers = parseInt(req.body.maxRedeemers)
      months = parseInt(req.body.months)
      timestamp = req.body.stripe?.timestamp
      token = req.body.stripe?.token

      return @sendBadInputError(res) unless isNaN(maxRedeemers) is false and maxRedeemers > 0
      return @sendBadInputError(res) unless isNaN(months) is false and months > 0
      return @sendError(res, 403, "Users or Months must be greater than 3") if maxRedeemers < 3 and months < 3

      Product.findOne({name: 'prepaid_subscription'}).exec (err, product) =>
        return @sendDatabaseError(res, err) if err
        return @sendNotFoundError(res, 'prepaid_subscription product not found') if not product
          
        @purchasePrepaidTerminalSubscription req.user, description, maxRedeemers, months, timestamp, token, product, (err, prepaid) =>
          return @sendDatabaseError(res, err) if err
          @sendSuccess(res, prepaid.toObject())

    else if req.body.type is 'course'
      maxRedeemers = parseInt(req.body.maxRedeemers)
      timestamp = req.body.stripe?.timestamp
      token = req.body.stripe?.token

      return @sendBadInputError(res) unless isNaN(maxRedeemers) is false and maxRedeemers > 0

      Product.findOne({name: 'course'}).exec (err, product) =>
        return @sendDatabaseError(res, err) if err
        return @sendNotFoundError(res, 'course product not found') if not product

        @purchasePrepaidCourse req.user, maxRedeemers, timestamp, token, product, (err, prepaid) =>
          # TODO: this badinput detection is fragile, in course instance handler as well
          return @sendBadInputError(res, err) if err is 'Missing required Stripe token'
          return @sendDatabaseError(res, err) if err
          @sendSuccess(res, prepaid.toObject())
    else
      @sendForbiddenError(res)

  purchasePrepaidCourse: (user, maxRedeemers, timestamp, token, product, done) ->
    type = 'course'

    amount = maxRedeemers * product.get('amount')
    if amount > 0 and not (token or user.isAdmin())
      @logError(user, "Purchase prepaid courses missing required Stripe token #{amount}")
      return done('Missing required Stripe token')

    if amount is 0 or user.isAdmin()
      @createPrepaid(user, type, maxRedeemers, {}, done)

    else
      StripeUtils.getCustomer user, token, (err, customer) =>
        if err
          @logError(user, "Stripe getCustomer error: #{JSON.stringify(err)}")
          return done(err)

        metadata =
          type: type
          userID: user.id
          timestamp: parseInt(timestamp)
          maxRedeemers: maxRedeemers
          productID: "prepaid #{type}"

        StripeUtils.createCharge user, amount, metadata, (err, charge) =>
          if err
            @logError(user, "createCharge error: #{JSON.stringify(err)}")
            return done(err)

          StripeUtils.createPayment user, charge, (err, payment) =>
            if err
              @logError(user, "createPayment error: #{JSON.stringify(err)}")
              return done(err)
            msg = "Prepaid code purchased: #{type} seats=#{maxRedeemers} #{user.get('email')}"
            hipchat.sendHipChatMessage msg, ['tower']
            @createPrepaid(user, type, maxRedeemers, {}, done)

  purchasePrepaidTerminalSubscription: (user, description, maxRedeemers, months, timestamp, token, product, done) ->
    type = 'terminal_subscription'

    StripeUtils.getCustomer user, token, (err, customer) =>
      if err
        @logError(user, "getCustomer error: #{JSON.stringify(err)}")
        return done(err)

      metadata =
        type: type
        userID: user.id
        timestamp: parseInt(timestamp)
        description: description
        maxRedeemers: maxRedeemers
        months: months
        productID: "prepaid #{type}"

      amount = utils.getPrepaidCodeAmount(product.get('amount'), maxRedeemers, months)

      StripeUtils.createCharge user, amount, metadata, (err, charge) =>
        if err
          @logError(user, "createCharge error: #{JSON.stringify(err)}")
          return done(err)

        StripeUtils.createPayment user, charge, (err, payment) =>
          if err
            @logError(user, "createPayment error: #{JSON.stringify(err)}")
            return done(err)

          Prepaid.generateNewCode (code) =>
            return done('Database error.') unless code
            prepaid = new Prepaid
              creator: user._id
              type: type
              code: code
              maxRedeemers: parseInt(maxRedeemers)
              redeemers: []
              properties:
                months: months
            prepaid.save (err) =>
              return done(err) if err
              msg = "Prepaid code purchased: #{type} users=#{maxRedeemers} months=#{months} #{user.get('email')}"
              hipchat.sendHipChatMessage msg, ['tower']
              return done(null, prepaid)


  get: (req, res) ->
    if creator = req.query.creator
      return @sendForbiddenError(res) unless req.user and (req.user.isAdmin() or creator is req.user.id)
      return @sendBadInputError(res, 'Bad creator') unless utils.isID creator
      q = {
        _id: {$gt: cutoffID}
        creator: mongoose.Types.ObjectId(creator)
        type: 'course'
      }
      Prepaid.find q, (err, prepaids) =>
        return @sendDatabaseError(res, err) if err
        documents = []
        for prepaid in prepaids
          documents.push(@formatEntity(req, prepaid)) unless prepaid.get('properties')?.endDate < new Date()
        return @sendSuccess(res, documents)
    else
      super(arguments...)

  makeNewInstance: (req) ->
    prepaid = super(req)
    prepaid.set('redeemers', [])
    return prepaid

module.exports = new PrepaidHandler()
