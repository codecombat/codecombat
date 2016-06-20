# Not paired with a document in the DB, just handles coordinating between
# the stripe property in the user with what's being stored in Stripe.

log = require 'winston'
MongoClient = require('mongodb').MongoClient
mongoose = require 'mongoose'
async = require 'async'
config = require '../../server_config'
Handler = require '../commons/Handler'
slack = require '../slack'
discountHandler = require './discount_handler'
Prepaid = require '../models/Prepaid'
User = require '../models/User'
{findStripeSubscription} = require '../lib/utils'
{getSponsoredSubsAmount} = require '../../app/core/utils'
StripeUtils = require '../lib/stripe_utils'
moment = require 'moment'
Product = require '../models/Product'

recipientCouponID = 'free'

class SubscriptionHandler extends Handler
  logSubscriptionError: (user, msg) ->
    log.warn "Subscription Error: #{user.get('slug')} (#{user._id}): '#{msg}'"

  getByRelationship: (req, res, args...) ->
    return @getStripeEvents(req, res) if args[1] is 'stripe_events'
    return @getStripeInvoices(req, res) if args[1] is 'stripe_invoices'
    return @getStripeSubscriptions(req, res) if args[1] is 'stripe_subscriptions'
    return @getSubscribers(req, res) if args[1] is 'subscribers'
    return @purchaseYearSale(req, res) if args[1] is 'year_sale'
    return @subscribeWithPrepaidCode(req, res) if args[1] is 'subscribe_prepaid'
    super(arguments...)

  getStripeEvents: (req, res) ->
    # console.log 'subscription_handler getStripeEvents', req.body?.options
    return @sendForbiddenError(res) unless req.user?.isAdmin()
    stripe.events.list req.body.options, (err, events) =>
      return @sendDatabaseError(res, err) if err
      @sendSuccess(res, events)

  getStripeInvoices: (req, res) ->
    # console.log 'subscription_handler getStripeInvoices'
    return @sendForbiddenError(res) unless req.user?.isAdmin()

    stripe.invoices.list req.body.options, (err, invoices) =>
      return @sendDatabaseError(res, err) if err
      @sendSuccess(res, invoices)

  getStripeSubscriptions: (req, res) ->
    # console.log 'subscription_handler getStripeSubscriptions'
    return @sendForbiddenError(res) unless req.user?.isAdmin()
    stripeSubscriptions = []
    createGetSubFn = (customerID, subscriptionID) =>
      (done) =>
        stripe.customers.retrieveSubscription customerID, subscriptionID, (err, subscription) =>
          # TODO: return error instead of ignore?
          stripeSubscriptions.push(subscription) unless err
          done()
    tasks = []
    for subscription in req.body.subscriptions
      tasks.push createGetSubFn(subscription.customerID, subscription.subscriptionID)
    async.parallel tasks, (err, results) =>
      return @sendDatabaseError(res, err) if err
      @sendSuccess(res, stripeSubscriptions)

  getSubscribers: (req, res) ->
    # console.log 'subscription_handler getSubscribers'
    return @sendForbiddenError(res) unless req.user?.isAdmin()
    subscriberUserIDs = req.body.ids or []

    User.find {_id: {$in: subscriberUserIDs}}, (err, users) =>
      return @sendDatabaseError(res, err) if err
      userMap = {}
      userMap[user.id] = user.toObject() for user in users

      try
        # Get conversion data directly from analytics database and add it to results
        url = "mongodb://#{config.mongo.analytics_host}:#{config.mongo.analytics_port}/#{config.mongo.analytics_db}"
        MongoClient.connect url, (err, db) =>
          if err
            log.debug 'Analytics connect error: ' + err
            return @sendDatabaseError(res, err)
          userEventMap = {}
          events = ['Finished subscription purchase', 'Show subscription modal']
          query = {$and: [{user: {$in: subscriberUserIDs}}, {event: {$in: events}}]}
          db.collection('log').find(query).sort({_id: -1}).each (err, doc) =>
            if err
              db.close()
              return @sendDatabaseError(res, err)
            if (doc)
              userEventMap[doc.user] ?= []
              userEventMap[doc.user].push doc
            else
              db.close()
              for userID, eventList of userEventMap
                finishedPurchase = false
                for event in eventList
                  finishedPurchase = true if event.event is 'Finished subscription purchase'
                  if finishedPurchase
                    if event.event is 'Show subscription modal' and event.properties?.level?
                      userMap[userID].conversion = event.properties.level
                      break
                    else if event.event is 'Show subscription modal' and event.properties?.label in ['buy gems modal', 'check private clan', 'create clan']
                      userMap[userID].conversion = event.properties.label
                      break
              @sendSuccess(res, userMap)
      catch err
        log.debug 'Analytics error:\n' + err
        @sendSuccess(res, userMap)

  cancelSubscriptionImmediately: (user, subscription, done) =>
    return done() unless user and subscription
    stripe.customers.cancelSubscription subscription.customer, subscription.id, (err) =>
      return done(err) if err
      stripeInfo = _.cloneDeep(user.get('stripe') ? {})
      delete stripeInfo.planID
      delete stripeInfo.prepaidCode
      delete stripeInfo.subscriptionID
      user.set('stripe', stripeInfo)
      user.save (err) =>
        return done(err) if err
        done()


  purchaseYearSale: (req, res) ->
    return @sendForbiddenError(res) unless req.user?
    return @sendForbiddenError(res) if req.user?.get('stripe')?.sponsorID

    StripeUtils.getCustomer req.user, req.body.stripe?.token, (err, customer) =>
      if err
        @logSubscriptionError(req.user, "Purchase year sale get customer: #{JSON.stringify(err)}")
        return @sendDatabaseError(res, err)

      findStripeSubscription customer.id, subscriptionID: req.user.get('stripe')?.subscriptionID, (subscription) =>
        stripeSubscriptionPeriodEndDate = new Date(subscription.current_period_end * 1000) if subscription

        @cancelSubscriptionImmediately req.user, subscription, (err) =>
          if err
            @logSubscriptionError(user, "Purchase year sale Stripe cancel subscription error: #{JSON.stringify(err)}")
            return @sendDatabaseError(res, err)

          Product.findOne({name: 'year_subscription'}).exec (err, product) =>
            return @sendDatabaseError(res, err) if err
            return @sendNotFoundError(res, 'year_subscription product not found') if not product

            metadata =
              type: req.body.type
              userID: req.user._id + ''
              gems: product.get('gems')
              timestamp: parseInt(req.body.stripe?.timestamp)
              description: req.body.description

            StripeUtils.createCharge req.user, product.get('amount'), metadata, (err, charge) =>
              if err
                @logSubscriptionError(req.user, "Purchase year sale create charge: #{JSON.stringify(err)}")
                return @sendDatabaseError(res, err)

              StripeUtils.createPayment req.user, charge, {}, (err, payment) =>
                if err
                  @logSubscriptionError(req.user, "Purchase year sale create payment: #{JSON.stringify(err)}")
                  return @sendDatabaseError(res, err)

                # Add terminal subscription to User with extensions for existing subscriptions
                stripeInfo = _.cloneDeep(req.user.get('stripe') ? {})
                endDate = new Date()
                if stripeSubscriptionPeriodEndDate
                  endDate = stripeSubscriptionPeriodEndDate
                else if _.isString(stripeInfo.free) and new Date() < new Date(stripeInfo.free)
                  endDate = new Date(stripeInfo.free)
                endDate.setUTCFullYear(endDate.getUTCFullYear() + 1)
                stripeInfo.free = endDate.toISOString().substring(0, 10)
                req.user.set('stripe', stripeInfo)

                # Add year's worth of gems to User
                purchased = _.clone(req.user.get('purchased'))
                purchased ?= {}
                purchased.gems ?= 0
                purchased.gems += parseInt(charge.metadata.gems) if charge.metadata.gems
                req.user.set('purchased', purchased)

                req.user.save (err, user) =>
                  if err
                    @logSubscriptionError(req.user, "User save error: #{JSON.stringify(err)}")
                    return @sendDatabaseError(res, err)
                  try
                    msg = "#{req.user.get('email')} paid #{payment.get('amount')} for year campaign subscription"
                    slack.sendSlackMessage msg, ['tower']
                  catch error
                    @logSubscriptionError(req.user, "Year sub sale Slack tower msg error: #{JSON.stringify(error)}")
                  @sendSuccess(res, user)

  subscribeWithPrepaidCode: (req, res) ->
    return @sendUnauthorizedError(res) unless req.user?
    return @sendBadInputError(res,"You must provide a valid prepaid code") unless req.body?.ppc

    # Check if code exists and has room for more redeemers
    Prepaid.findOne({ code: req.body.ppc?.toString() }).exec (err, prepaid) =>
      if err
        @logSubscriptionError(req.user, "Redeem Prepaid Code find: #{JSON.stringify(err)}")
        return @sendDatabaseError(res, err)
      unless prepaid
        @logSubscriptionError(req.user, "Could not find prepaid code #{req.body.ppc?.toString()}")
        return @sendNotFoundError(res, "Prepaid not found")

      oldRedeemers = prepaid.get('redeemers') ? []
      return @sendError(res, 403, "Too many redeemers") if oldRedeemers.length >= prepaid.get('maxRedeemers')
      months = parseInt(prepaid.get('properties')?.months)
      return @sendBadInputError(res, "Bad months") if isNaN(months) or months < 1
      for redeemer in oldRedeemers
        return @sendError(res, 403, "User already redeemed") if redeemer.userID.equals(req.user._id)

      @redeemPrepaidCode(req, res, months)

  redeemPrepaidCode: (req, res, months) =>
    return @sendUnauthorizedError(res) unless req.user?
    return @sendForbiddenError(res) unless req.body?.ppc
    return @sendForbiddenError(res) if isNaN(months) or months < 1

    newRedeemerPush = { $push: { redeemers : { date: new Date(), userID: req.user._id } }}

    Prepaid.update { 'code': req.body.ppc, 'redeemers.userID': { $ne: req.user._id }, '$where': 'this.redeemers.length < this.maxRedeemers'}, newRedeemerPush, (err, result) =>
      if err
        @logSubscriptionError(req.user, "Subscribe with Prepaid Code update: #{JSON.stringify(err)}")
        return @sendDatabaseError(res, err)

      return @sendError(res, 403, "Can't add user to prepaid redeemers") if result.nModified isnt 1

      customerID = req.user.get('stripe')?.customerID
      subscriptionID = req.user.get('stripe')?.subscriptionID
      findStripeSubscription customerID, subscriptionID: subscriptionID, (subscription) =>
        stripeSubscriptionPeriodEndDate = new Date(subscription.current_period_end * 1000) if subscription

        @cancelSubscriptionImmediately req.user, subscription, (err) =>
          if err
            @logSubscriptionError(user, "Redeem Prepaid Code Stripe cancel subscription error: #{JSON.stringify(err)}")
            return @sendDatabaseError(res, err)

          Product.findOne({name: 'basic_subscription'}).exec (err, product) =>
            return @sendDatabaseError(res, err) if err
            return @sendNotFoundError(res, 'basic_subscription product not found') if not product

            # Add terminal subscription to User, extending existing subscriptions
            # TODO: refactor this into some form useable by both this and purchaseYearSale
            stripeInfo = _.cloneDeep(req.user.get('stripe') ? {})
            endDate = new moment()
            if stripeSubscriptionPeriodEndDate
              endDate = new moment(stripeSubscriptionPeriodEndDate)
            else if _.isString(stripeInfo.free) and new moment().isBefore(new moment(stripeInfo.free))
              endDate = new moment(stripeInfo.free)

            endDate = endDate.add(months, 'months')
            stripeInfo.free = endDate.toISOString().substring(0, 10)
            req.user.set('stripe', stripeInfo)

            # Add gems to User
            purchased = _.clone(req.user.get('purchased'))
            purchased ?= {}
            purchased.gems ?= 0
            purchased.gems += product.get('gems') * months if product.get('gems')
            req.user.set('purchased', purchased)

            req.user.save (err, user) =>
              if err
                @logSubscriptionError(req.user, "User save error: #{JSON.stringify(err)}")
                return @sendDatabaseError(res, err)
              @sendSuccess(res, user)

  subscribeUser: (req, user, done) ->
    if (not req.user) or req.user.isAnonymous() or user.isAnonymous()
      return done({res: 'You must be signed in to subscribe.', code: 403})

    token = req.body.stripe.token
    prepaidCode = req.body.stripe.prepaidCode
    customerID = user.get('stripe')?.customerID
    if not (token or customerID or prepaidCode)
      @logSubscriptionError(user, 'Missing Stripe token or customer ID or prepaid code')
      return done({res: 'Missing Stripe token or customer ID or prepaid code', code: 422})

    # Get Stripe customer
    if customerID
      if token
        stripe.customers.update customerID, { card: token }, (err, customer) =>
          if err or not customer
            # should not happen outside of test and production polluting each other
            @logSubscriptionError(user, 'Cannot find customer: ' + customerID + '\n\n' + err)
            return done({res: 'Cannot find customer.', code: 404})
          @checkForCoupon(req, user, customer, done)
      else
        stripe.customers.retrieve customerID, (err, customer) =>
          if err
            @logSubscriptionError(user, 'Stripe customer retrieve error. ' + err)
            return done({res: 'Database error.', code: 500})
          @checkForCoupon(req, user, customer, done)
    else
      options =
        email: user.get('email')
        metadata: { id: user._id + '', slug: user.get('slug') }
      options.card = token if token?
      stripe.customers.create options, (err, customer) =>
        if err
          if err.type in ['StripeCardError', 'StripeInvalidRequestError']
            return done({res: 'Card error', code: 402})
          else
            @logSubscriptionError(user, 'Stripe customer creation error. ' + err)
            return done({res: 'Database error.', code: 500})

        stripeInfo = _.cloneDeep(user.get('stripe') ? {})
        stripeInfo.customerID = customer.id
        user.set('stripe', stripeInfo)
        user.save (err) =>
          if err
            @logSubscriptionError(user, 'Stripe customer id save db error. ' + err)
            return done({res: 'Database error.', code: 500})
          @checkForCoupon(req, user, customer, done)

  checkForCoupon: (req, user, customer, done) ->
    # Check if user is subscribing someone else
    if req.body.stripe?.subscribeEmails?
      return @updateStripeRecipientSubscriptions req, user, customer, done

    if user.get('stripe')?.sponsorID
      return done({res: 'You already have a sponsored subscription.', code: 403})

    if req.body?.stripe?.prepaidCode
      Prepaid.findOne code: req.body.stripe.prepaidCode, (err, prepaid) =>
        if err
          @logSubscriptionError(user, 'Prepaid lookup error. ' + err)
          return done({res: 'Database error.', code: 500})
        return done({res: 'Prepaid not found', code: 404}) unless prepaid?
        return done({res: 'Prepaid not for subscription', code: 403}) unless prepaid.get('type') is 'subscription'
        if prepaid.get('redeemers')?.length >= prepaid.get('maxRedeemers')
          @logSubscriptionError(user, "Prepaid #{prepaid.id} note active")
          return done({res: 'Prepaid not active', code: 403})
        unless couponID = prepaid.get('properties')?.couponID
          @logSubscriptionError(user, "Prepaid #{prepaid.id} has no couponID")
          return done({res: 'Database error.', code: 500})

        redeemers = prepaid.get('redeemers') ? []
        if _.find(redeemers, (a) -> a.userID?.equals(user.get('_id')))
          @logSubscriptionError(user, "Prepaid code already redeemed by #{user.id}")
          return done({res: 'Prepaid code already redeemed', code: 403})

        # Redeem prepaid code
        query = Prepaid.$where("'#{prepaid.get('_id').valueOf()}' === this._id.valueOf() && (!this.redeemers || this.redeemers.length < this.maxRedeemers)")
        redeemers.push
          userID: user.get('_id')
          date: new Date()
        update = {redeemers: redeemers}
        Prepaid.update query, update, {}, (err, result) =>
          if err
            @logSubscriptionError(user, 'Prepaid update error. ' + err)
            return done({res: 'Database error.', code: 500})
          if result.nModified > 1
            @logSubscriptionError(user, "Prepaid nModified=#{result.nModified} error.")
            return done({res: 'Database error.', code: 500})
          if result.nModified < 1
            return done({res: 'Prepaid not active', code: 403})

          # Update user
          stripeInfo = _.cloneDeep(user.get('stripe') ? {})
          stripeInfo.couponID = couponID
          stripeInfo.prepaidCode = req.body.stripe.prepaidCode
          user.set('stripe', stripeInfo)
          @checkForExistingSubscription(req, user, customer, couponID, done)

    else
      couponID = user.get('stripe')?.couponID
      if user.get('country') is 'brazil'
        couponID ?= 'brazil'
      # SALE LOGIC
      # overwrite couponID with another for everyone-sales
      #couponID = 'hoc_399' if not couponID
      @checkForExistingSubscription(req, user, customer, couponID, done)

  checkForExistingSubscription: (req, user, customer, couponID, done) ->
    findStripeSubscription customer.id, subscriptionID: user.get('stripe')?.subscriptionID, (subscription) =>

      if subscription

        if subscription.cancel_at_period_end
          # Things are a little tricky here. Can't re-enable a cancelled subscription,
          # so it needs to be deleted, but also don't want to charge for the new subscription immediately.
          # So delete the cancelled subscription (no at_period_end given here) and give the new
          # subscription a trial period that ends when the cancelled subscription would have ended.
          stripe.customers.cancelSubscription subscription.customer, subscription.id, (err) =>
            if err
              @logSubscriptionError(user, 'Stripe cancel subscription error. ' + err)
              return done({res: 'Database error.', code: 500})
            options = { plan: 'basic', metadata: {id: user.id}, trial_end: subscription.current_period_end }
            options.coupon = couponID if couponID
            stripe.customers.createSubscription customer.id, options, (err, subscription) =>
              if err
                @logSubscriptionError(user, 'Stripe customer plan resetting error. ' + err)
                return done({res: 'Database error.', code: 500})
              @updateUser(req, user, customer, subscription, false, done)

        else if couponID
          # Update subscription with given couponID
          stripe.customers.updateSubscription customer.id, subscription.id, coupon: couponID, (err, subscription) =>
            if err
              @logSubscriptionError(user, 'Stripe update subscription coupon error. ' + err)
              return done({res: 'Database error.', code: 500})
            @updateUser(req, user, customer, subscription, false, done)

        else
          # Skip creating the subscription
          @updateUser(req, user, customer, subscription, false, done)

      else
        options = { plan: 'basic', metadata: {id: user.id}}
        options.coupon = couponID if couponID
        stripe.customers.createSubscription customer.id, options, (err, subscription) =>
          if err
            @logSubscriptionError(user, 'Stripe customer plan setting error. ' + err)
            return done({res: 'Database error.', code: 500})

          @updateUser(req, user, customer, subscription, true, done)

  updateUser: (req, user, customer, subscription, increment, done) ->
    stripeInfo = _.cloneDeep(user.get('stripe') ? {})
    stripeInfo.planID = 'basic'
    stripeInfo.subscriptionID = subscription.id
    stripeInfo.customerID = customer.id

    # To make sure things work for admins, who are mad with power
    # And, so Handler.saveChangesToDocument doesn't undo all our saves here
    req.body.stripe = stripeInfo
    user.set('stripe', stripeInfo)

    productName = 'basic_subscription'
    if user.get('country') in ['brazil']
      productName = "#{user.get('country')}_basic_subscription"

    Product.findOne({name: productName}).exec (err, product) =>
      return done({res: 'Database error.', code: 500}) if err
      return done({res: 'basic_subscription product not found.', code: 404}) if not product
      
      if increment
        purchased = _.clone(user.get('purchased'))
        purchased ?= {}
        purchased.gems ?= 0
        purchased.gems += product.get('gems') if product.get('gems')
        user.set('purchased', purchased)

      user.save (err) =>
        if err
          @logSubscriptionError(user, 'Stripe user plan saving error. ' + err)
          return done({res: 'Database error.', code: 500})
        done()

  updateStripeRecipientSubscriptions: (req, user, customer, done) ->
    return done({res: 'Database error.', code: 500}) unless req.body.stripe?.subscribeEmails?

    emails = req.body.stripe.subscribeEmails.map((email) -> email.trim().toLowerCase() unless _.isEmpty(email))
    _.remove(emails, (email) -> _.isEmpty(email))

    User.find {emailLower: {$in: emails}}, (err, recipients) =>
      if err
        @logSubscriptionError(user, "User lookup error. " + err)
        return done({res: 'Database error.', code: 500})

      createUpdateFn = (recipient) =>
        (done) =>
          # Find existing recipient subscription
          findStripeSubscription customer.id, userID: recipient.id, (subscription) =>

            if subscription
              if subscription.cancel_at_period_end
                # Things are a little tricky here. Can't re-enable a cancelled subscription,
                # so it needs to be deleted, but also don't want to charge for the new subscription immediately.
                # So delete the cancelled subscription (no at_period_end given here) and give the new
                # subscription a trial period that ends when the cancelled subscription would have ended.
                stripe.customers.cancelSubscription subscription.customer, subscription.id, (err) =>
                  if err
                    @logSubscriptionError(user, 'Stripe cancel subscription error. ' + err)
                    return done({res: 'Database error.', code: 500})

                  options =
                    plan: 'basic'
                    coupon: recipientCouponID
                    metadata: {id: recipient.id}
                    trial_end: subscription.current_period_end
                  stripe.customers.createSubscription customer.id, options, (err, subscription) =>
                    if err
                      @logSubscriptionError(user, 'Stripe new subscription error. ' + err)
                      return done({res: 'Database error.', code: 500})
                    done(null, recipient: recipient, subscription: subscription, increment: false)
              else
                # Can skip creating the subscription
                done(null, recipient: recipient, subscription: subscription, increment: false)

            else
              options =
                plan: 'basic'
                coupon: recipientCouponID
                metadata: {id: recipient.id}
              stripe.customers.createSubscription customer.id, options, (err, subscription) =>
                if err
                  @logSubscriptionError(user, 'Stripe new subscription error. ' + err)
                  return done({res: 'Database error.', code: 500})
                done(null, recipient: recipient, subscription: subscription, increment: true)

      tasks = []
      for recipient in recipients
        continue if recipient.id is user.id
        continue if recipient.get('stripe')?.subscriptionID?
        continue if recipient.get('stripe')?.sponsorID? and recipient.get('stripe')?.sponsorID isnt user.id
        tasks.push createUpdateFn(recipient)

      # NOTE: async.parallel yields this error:
      # Subscription Error: user23 (54fe3c8fea98978efa469f3b): 'Stripe new subscription error. Error: Request rate limit exceeded'
      async.series tasks, (err, results) =>
        return done(err) if err
        @updateCocoRecipientSubscriptions(req, user, customer, results, done)

  updateCocoRecipientSubscriptions: (req, user, customer, stripeRecipients, done) ->
    # Update recipients list
    stripeInfo = _.cloneDeep(user.get('stripe') ? {})
    stripeInfo.recipients ?= []
    stripeRecipientIDs = (sub.recipient.id for sub in stripeRecipients)
    _.remove(stripeInfo.recipients, (s) -> s.userID in stripeRecipientIDs)
    for sub in stripeRecipients
      stripeInfo.recipients.push
        userID: sub.recipient.id
        subscriptionID: sub.subscription.id
        couponID: recipientCouponID

    # TODO: how does token get removed for personal subs?
    delete stripeInfo.subscribeEmails
    delete stripeInfo.token
    req.body.stripe = stripeInfo
    user.set('stripe', stripeInfo)
    user.save (err) =>
      if err
        @logSubscriptionError(user, 'User saving stripe error. ' + err)
        return done({res: 'Database error.', code: 500})

      Product.findOne({name: 'basic_subscription'}).exec (err, product) =>
        return @sendDatabaseError(res, err) if err
        return @sendNotFoundError(res, 'basic_subscription product not found') if not product

        createUpdateFn = (recipient, increment) =>
          (done) =>
            # Update recipient
            stripeInfo = _.cloneDeep(recipient.get('stripe') ? {})
            stripeInfo.sponsorID = user.id
            recipient.set 'stripe', stripeInfo
            if increment
              purchased = _.clone(recipient.get('purchased'))
              purchased ?= {}
              purchased.gems ?= 0
              purchased.gems += product.get('gems') if product.get('gems')
              recipient.set('purchased', purchased)
            recipient.save (err) =>
              if err
                @logSubscriptionError(user, 'Stripe user saving stripe error. ' + err)
                return done({res: 'Database error.', code: 500})
              done()

        tasks = []
        for sub in stripeRecipients
          tasks.push createUpdateFn(sub.recipient, sub.increment)

        async.parallel tasks, (err, results) =>
          return done(err) if err
          @updateStripeSponsorSubscription(req, user, customer, product, done)

  updateStripeSponsorSubscription: (req, user, customer, product, done) ->
    stripeInfo = user.get('stripe') ? {}
    numSponsored = stripeInfo.recipients.length
    quantity = getSponsoredSubsAmount(product.get('amount'), numSponsored, stripeInfo.subscriptionID?)

    findStripeSubscription customer.id, subscriptionID: stripeInfo.sponsorSubscriptionID, (subscription) =>
      if stripeInfo.sponsorSubscriptionID? and not subscription?
        @logSubscriptionError(user, "Internal sponsor subscription #{stripeInfo.sponsorSubscriptionID} not found on Stripe customer #{customer.id}")
        return done({res: 'Database error.', code: 500})

      if subscription
        return done() if quantity is subscription.quantity # E.g. cancelled sub has been resubbed

        options = quantity: quantity
        stripe.customers.updateSubscription customer.id, stripeInfo.sponsorSubscriptionID, options, (err, subscription) =>
          if err
            @logSubscriptionError(user, 'Stripe updating subscription quantity error. ' + err)
            return done({res: 'Database error.', code: 500})

          # Invoice proration immediately
          stripe.invoices.create customer: customer.id, (err, invoice) =>
            if err
              @logSubscriptionError(user, 'Stripe proration invoice error. ' + err)
              return done({res: 'Database error.', code: 500})
            done()
      else
        options =
          plan: 'incremental'
          metadata: {id: user.id}
          quantity: quantity
        stripe.customers.createSubscription customer.id, options, (err, subscription) =>
          if err
            @logSubscriptionError(user, 'Stripe new subscription error. ' + err)
            return done({res: 'Database error.', code: 500})
          @updateCocoSponsorSubscription(req, user, subscription, done)

  updateCocoSponsorSubscription: (req, user, subscription, done) ->
    stripeInfo = _.cloneDeep(user.get('stripe') ? {})
    stripeInfo.sponsorSubscriptionID = subscription.id
    req.body.stripe = stripeInfo
    user.set('stripe', stripeInfo)
    user.save (err) =>
      if err
        @logSubscriptionError(user, 'Saving user stripe error. ' + err)
        return done({res: 'Database error.', code: 500})
      done()

  unsubscribeUser: (req, user, done) ->
    # Check if user is subscribing someone else
    return @unsubscribeRecipient(req, user, done) if req.body.stripe?.unsubscribeEmail?

    stripeInfo = _.cloneDeep(user.get('stripe') ? {})
    stripe.customers.cancelSubscription stripeInfo.customerID, stripeInfo.subscriptionID, { at_period_end: true }, (err) =>
      if err
        @logSubscriptionError(user, 'Stripe cancel subscription error. ' + err)
        return done({res: 'Database error.', code: 500})
      delete stripeInfo.planID
      user.set('stripe', stripeInfo)
      req.body.stripe = stripeInfo
      user.save (err) =>
        if err
          @logSubscriptionError(user, 'User save unsubscribe error. ' + err)
          return done({res: 'Database error.', code: 500})
        done()

  unsubscribeRecipient: (req, user, done) ->
    return done({res: 'Database error.', code: 500}) unless req.body.stripe?.unsubscribeEmail?

    email = req.body.stripe.unsubscribeEmail.trim().toLowerCase()
    return done({res: 'Database error.', code: 500}) if _.isEmpty(email)

    deleteUserStripeProp = (user, propName) ->
      stripeInfo = _.cloneDeep(user.get('stripe') ? {})
      delete stripeInfo[propName]
      if _.isEmpty stripeInfo
        user.set 'stripe', undefined
      else
        user.set 'stripe', stripeInfo

    User.findOne {emailLower: email}, (err, recipient) =>
      if err
        @logSubscriptionError(user, "User lookup error. " + err)
        return done({res: 'Database error.', code: 500})
      unless recipient
        @logSubscriptionError(user, "Recipient #{email} not found.")
        return done({res: 'Database error.', code: 500})

      # Check recipient is currently sponsored
      stripeRecipient = recipient.get 'stripe' ? {}
      if stripeRecipient?.sponsorID isnt user.id
        @logSubscriptionError(user, "Recipient #{recipient.id} not sponsored by #{user.id}. ")
        return done({res: 'Can only unsubscribe sponsored subscriptions.', code: 403})

      # Find recipient subscription
      stripeInfo = _.cloneDeep(user.get('stripe') ? {})
      for sponsored in stripeInfo.recipients
        if sponsored.userID is recipient.id
          sponsoredEntry = sponsored
          break
      unless sponsoredEntry?
        @logSubscriptionError(user, 'Unable to find recipient subscription. ')
        return done({res: 'Database error.', code: 500})

      Product.findOne({name: 'basic_subscription'}).exec (err, product) =>
        return @sendDatabaseError(res, err) if err
        return @sendNotFoundError(res, 'basic_subscription product not found') if not product

        # Update recipient user
        deleteUserStripeProp(recipient, 'sponsorID')
        recipient.save (err) =>
          if err
            @logSubscriptionError(user, 'Recipient user save unsubscribe error. ' + err)
            return done({res: 'Database error.', code: 500})

          # Cancel Stripe subscription
          stripe.customers.cancelSubscription stripeInfo.customerID, sponsoredEntry.subscriptionID, (err) =>
            if err
              @logSubscriptionError(user, "Stripe cancel sponsored subscription failed. " + err)
              return done({res: 'Database error.', code: 500})

            # Update sponsor user
            _.remove(stripeInfo.recipients, (s) -> s.userID is recipient.id)
            delete stripeInfo.unsubscribeEmail
            user.set('stripe', stripeInfo)
            req.body.stripe = stripeInfo
            user.save (err) =>
              if err
                @logSubscriptionError(user, 'Sponsor user save unsubscribe error. ' + err)
                return done({res: 'Database error.', code: 500})

              return done() unless stripeInfo.sponsorSubscriptionID?

              # Update sponsored subscription quantity
              options =
                quantity: getSponsoredSubsAmount(product.get('amount'), stripeInfo.recipients.length, stripeInfo.subscriptionID?)
              stripe.customers.updateSubscription stripeInfo.customerID, stripeInfo.sponsorSubscriptionID, options, (err, subscription) =>
                if err
                  @logSubscriptionError(user, 'Sponsored subscription quantity update error. ' + JSON.stringify(err))
                  return done({res: 'Database error.', code: 500})
                done()

module.exports = new SubscriptionHandler()
