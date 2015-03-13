# Not paired with a document in the DB, just handles coordinating between
# the stripe property in the user with what's being stored in Stripe.

async = require 'async'
Handler = require '../commons/Handler'
discountHandler = require './discount_handler'
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

  subscribeUser: (req, user, done) ->
    if (not req.user) or req.user.isAnonymous() or user.isAnonymous()
      return done({res: 'You must be signed in to subscribe.', code: 403})

    token = req.body.stripe.token
    customerID = user.get('stripe')?.customerID
    if not (token or customerID)
      @logSubscriptionError(user, 'Missing stripe token or customer ID.')
      return done({res: 'Missing stripe token or customer ID.', code: 422})

    # Create/retrieve Stripe customer
    if token
      if customerID
        stripe.customers.update customerID, { card: token }, (err, customer) =>
          if err or not customer
            # should not happen outside of test and production polluting each other
            @logSubscriptionError(user, 'Cannot find customer: ' + customerID + '\n\n' + err)
            return done({res: 'Cannot find customer.', code: 404})
          @checkForExistingSubscription(req, user, customer, done)

      else
        options =
          card: token
          email: user.get('email')
          metadata: { id: user._id + '', slug: user.get('slug') }
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
            @checkForExistingSubscription(req, user, customer, done)

    else
      stripe.customers.retrieve(customerID, (err, customer) =>
        if err
          @logSubscriptionError(user, 'Stripe customer retrieve error. ' + err)
          return done({res: 'Database error.', code: 500})
        @checkForExistingSubscription(req, user, customer, done)
      )

  checkForExistingSubscription: (req, user, customer, done) ->
    # Check if user is subscribing someone else
    if req.body.stripe?.subscribeEmails?
      return @updateStripeRecipientSubscriptions req, user, customer, done

    if user.get('stripe')?.sponsorID
      return done({res: 'You already have a sponsored subscription.', code: 403})

    couponID = user.get('stripe')?.couponID

    # SALE LOGIC
    # overwrite couponID with another for everyone-sales
    #couponID = 'hoc_399' if not couponID

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

        else
          # can skip creating the subscription
          return @updateUser(req, user, customer, subscription, false, done)

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
      user?.saveActiveUser 'subscribe'
      return done()

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
