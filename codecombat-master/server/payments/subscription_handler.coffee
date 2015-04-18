# Not paired with a document in the DB, just handles coordinating between
# the stripe property in the user with what's being stored in Stripe.

mongoose = require 'mongoose'
async = require 'async'
config = require '../../server_config'
Handler = require '../commons/Handler'
discountHandler = require './discount_handler'
Prepaid = require '../prepaids/Prepaid'
User = require '../users/User'
{findStripeSubscription} = require '../lib/utils'
{getSponsoredSubsAmount} = require '../../app/core/utils'

recipientCouponID = 'free'
subscriptions = {
  basic: {
    gems: 3500
    amount: 999 # For calculating incremental quantity before sub creation
  }
}

class SubscriptionHandler extends Handler
  logSubscriptionError: (user, msg) ->
    console.warn "Subscription Error: #{user.get('slug')} (#{user._id}): '#{msg}'"

  getByRelationship: (req, res, args...) ->
    return @getCancellations(req, res) if args[1] is 'cancellations'
    return @getSubscribers(req, res) if args[1] is 'subscribers'
    return @getSubscriptions(req, res) if args[1] is 'subscriptions'
    super(arguments...)

  getCancellations: (req, res) =>
    return @sendForbiddenError(res) unless req.user and req.user.isAdmin()
    @cancellations = []
    nextBatch = (starting_after, done) =>
      options = limit: 100
      options.starting_after = starting_after if starting_after
      stripe.customers.list options, (err, customers) =>
        return done(err) if err

        for customer in customers.data
          continue unless customer?.subscriptions?.data?.length > 0
          for subscription in customer.subscriptions.data
            continue unless subscription.plan.id is 'basic'

            amount = subscription.plan.amount
            if subscription?.discount?.coupon?
              if subscription.discount.coupon.percent_off
                amount = amount *  (100 - subscription.discount.coupon.percent_off) / 100;
              else if subscription.discount.coupon.amount_off
                amount -= subscription.discount.coupon.amount_off
            else if customer.discount?.coupon?
              if customer.discount.coupon.percent_off
                amount = amount *  (100 - customer.discount.coupon.percent_off) / 100
              else if customer.discount.coupon.amount_off
                amount -= customer.discount.coupon.amount_off

            continue unless amount > 0

            if subscription.cancel_at_period_end
              @cancellations.push
                cancel: new Date(subscription.canceled_at * 1000)
                subID: subscription.id

        if customers.has_more
          # console.log 'Fetching more customers', Object.keys(@cancellations).length
          return nextBatch(customers.data[customers.data.length - 1].id, done)
        else
          return done()
    nextBatch null, (err) =>
      return @sendDatabaseError(res, err) if err
      @sendSuccess(res, @cancellations)

  getSubscribers: (req, res) ->
    return @sendForbiddenError(res) unless req.user and req.user.isAdmin()

    maxReturnCount = req.body.maxCount or 20

    # @subscribers ?= []
    # return @sendSuccess(res, @subscribers) unless _.isEmpty(@subscribers)
    @subscribers = []

    subscriberIDs = []

    customersProcessed = 0
    nextBatch = (starting_after, done) =>
      options = limit: 100
      options.starting_after = starting_after if starting_after
      stripe.customers.list options, (err, customers) =>
        return done(err) if err
        customersProcessed += customers.data.length

        for customer in customers.data
          break unless @subscribers.length < maxReturnCount
          continue unless customer?.subscriptions?.data?.length > 0
          for subscription in customer.subscriptions.data
            continue unless subscription.plan.id is 'basic'

            amount = subscription.plan.amount
            if subscription?.discount?.coupon?
              if subscription.discount.coupon.percent_off
                amount = amount *  (100 - subscription.discount.coupon.percent_off) / 100;
              else if subscription.discount.coupon.amount_off
                amount -= subscription.discount.coupon.amount_off
            else if customer.discount?.coupon?
              if customer.discount.coupon.percent_off
                amount = amount *  (100 - customer.discount.coupon.percent_off) / 100
              else if customer.discount.coupon.amount_off
                amount -= customer.discount.coupon.amount_off

            continue unless amount > 0

            subscriber = start: new Date(subscription.start * 1000)
            if subscription.metadata?.id?
              subscriber.userID = subscription.metadata.id
              subscriberIDs.push subscription.metadata.id
            if subscription.cancel_at_period_end
              subscriber.cancel = new Date(subscription.canceled_at * 1000)
              subscriber.end = new Date(subscription.current_period_end * 1000)
            @subscribers.push(subscriber)

        if customers.has_more and @subscribers.length < maxReturnCount
          return nextBatch(customers.data[customers.data.length - 1].id, done)
        else
          return done()
    nextBatch null, (err) =>
      return @sendDatabaseError(res, err) if err
      User.find {_id: {$in: subscriberIDs}}, (err, users) =>
        return @sendDatabaseError(res, err) if err
        for user in users
          subscriber.user = user for subscriber in @subscribers when subscriber.userID is user.id
        @sendSuccess(res, @subscribers)

  getSubscriptions: (req, res) ->
    # Returns a list of active subscriptions
    # TODO: does not track sponsored subs, only basic
    # TODO: does not return free subs
    # TODO: add tests
    # TODO: aggregate this data daily instead of providing it on demand
    # TODO: take date range as input
    # TODO: are ended counts correct for today?  E.g. retries may complicate things.

    return @sendForbiddenError(res) unless req.user and req.user.isAdmin()

    # return @sendSuccess(res, @subs) unless _.isEmpty(@subs)
    @subMap = {}

    processInvoices = (starting_after, done) =>
      options = limit: 100
      options.starting_after = starting_after if starting_after
      stripe.invoices.list options, (err, invoices) =>
        return done(err) if err
        for invoice in invoices.data
          continue unless invoice.paid
          continue unless invoice.subscription
          continue unless invoice.total > 0
          continue unless invoice.lines?.data?[0]?.plan?.id is 'basic'
          subID = invoice.subscription
          invoiceDate = new Date(invoice.date * 1000)
          if subID of @subMap
            @subMap[subID].first = invoiceDate
          else
            @subMap[subID] =
              first: invoiceDate
              last: invoiceDate
              customerID: invoice.customer
        if invoices.has_more
          # console.log 'Fetching more invoices', Object.keys(@subMap).length
          return processInvoices(invoices.data[invoices.data.length - 1].id, done)
        else
          return done()

    processInvoices null, (err) =>
      return @sendDatabaseError(res, err) if err
      @subs = []
      for subID of @subMap
        sub =
          start: @subMap[subID].first
          subID: subID
          customerID: @subMap[subID].customerID
        sub.cancel = @subMap[subID].cancel if @subMap[subID].cancel
        oneMonthAgo = new Date()
        oneMonthAgo.setUTCMonth(oneMonthAgo.getUTCMonth() - 1)
        if @subMap[subID].last < oneMonthAgo
          sub.end = new Date(@subMap[subID].last)
          sub.end.setUTCMonth(sub.end.getUTCMonth() + 1)
        @subs.push sub
      @sendSuccess(res, @subs)

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
        return done({res: 'Prepaid has already been used', code: 403}) unless prepaid.get('status') is 'active'
        return done({res: 'Database error.', code: 500}) unless prepaid.get('properties')?.couponID
        couponID = prepaid.get('properties').couponID

        # Update user
        stripeInfo = _.cloneDeep(user.get('stripe') ? {})
        stripeInfo.couponID = couponID
        stripeInfo.prepaidCode = req.body.stripe.prepaidCode
        user.set('stripe', stripeInfo)
        @checkForExistingSubscription(req, user, customer, couponID, done)
    else
      couponID = user.get('stripe')?.couponID
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
                @logSubscriptionError(user, 'Stripe customer plan setting error. ' + err)
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

    if increment
      purchased = _.clone(user.get('purchased'))
      purchased ?= {}
      purchased.gems ?= 0
      purchased.gems += subscriptions.basic.gems # TODO: Put actual subscription amount here
      user.set('purchased', purchased)

    user.save (err) =>
      if err
        @logSubscriptionError(user, 'Stripe user plan saving error. ' + err)
        return done({res: 'Database error.', code: 500})

      if stripeInfo.prepaidCode?
        # Update prepaid to 'used'
        Prepaid.findOne code: stripeInfo.prepaidCode, (err, prepaid) =>
          if err
            @logSubscriptionError(user, 'Prepaid find error. ' + err)
            return done({res: 'Database error.', code: 500})
          unless prepaid?
            @logSubscriptionError(user, "Expected prepaid not found: #{stripeInfo.prepaidCode}")
            return done({res: 'Database error.', code: 500})
          prepaid.set('status', 'used')
          prepaid.set('redeemer', user.get('_id'))
          prepaid.save (err) =>
            if err
              @logSubscriptionError(user, 'Prepaid update error. ' + err)
              return done({res: 'Database error.', code: 500})
            done()
      else
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

      # NOTE: async.parellel yields this error:
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
            purchased.gems += subscriptions.basic.gems
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
        @updateStripeSponsorSubscription(req, user, customer, done)

  updateStripeSponsorSubscription: (req, user, customer, done) ->
    stripeInfo = user.get('stripe') ? {}
    numSponsored = stripeInfo.recipients.length
    quantity = getSponsoredSubsAmount(subscriptions.basic.amount, numSponsored, stripeInfo.subscriptionID?)

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

    User.findOne {emailLower: email}, (err, recipient) =>
      if err
        @logSubscriptionError(user, "User lookup error. " + err)
        return done({res: 'Database error.', code: 500})
      unless recipient
        @logSubscriptionError(user, "Recipient #{req.body.stripe.recipient} not found. " + err)
        return done({res: 'Database error.', code: 500})

      # Check recipient is currently sponsored
      stripeRecipient = recipient.get 'stripe' ? {}
      if stripeRecipient.sponsorID isnt user.id
        @logSubscriptionError(user, "Recipient #{req.body.stripe.recipient} not found. " + err)
        return done({res: 'Can only unsubscribe sponsored subscriptions.', code: 403})

      # Find recipient subscription
      stripeInfo = _.cloneDeep(user.get('stripe') ? {})
      for sponsored in stripeInfo.recipients
        if sponsored.userID is recipient.id
          sponsoredEntry = sponsored
          break
      unless sponsoredEntry?
        @logSubscriptionError(user, 'Unable to find sponsored subscription. ' + err)
        return done({res: 'Database error.', code: 500})

      # Cancel Stripe subscription
      stripe.customers.cancelSubscription stripeInfo.customerID, sponsoredEntry.subscriptionID, { at_period_end: true }, (err) =>
        if err or not recipient
          @logSubscriptionError(user, "Stripe cancel sponsored subscription failed. " + err)
          return done({res: 'Database error.', code: 500})

        delete stripeInfo.unsubscribeEmail
        user.set('stripe', stripeInfo)
        req.body.stripe = stripeInfo
        user.save (err) =>
          if err
            @logSubscriptionError(user, 'User save unsubscribe error. ' + err)
            return done({res: 'Database error.', code: 500})
          done()

module.exports = new SubscriptionHandler()
