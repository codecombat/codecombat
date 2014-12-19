# Not paired with a document in the DB, just handles coordinating between
# the stripe property in the user with what's being stored in Stripe.

Handler = require '../commons/Handler'
discountHandler = require './discount_handler'

subscriptions = {
  basic: {
    gems: 3500
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

    if token
      if customerID
        stripe.customers.update customerID, { card: token }, (err, customer) =>
          if err or not customer
            # should not happen outside of test and production polluting each other
            @logSubscriptionError(user, 'Cannot find customer: ', +customer.id + '\n\n' + err)
            return done({res: 'Cannot find customer.', code: 404})
          @checkForExistingSubscription(req, user, customer, done)

      else
        newCustomer = {
          card: token
          email: user.get('email')
          metadata: { id: user._id + '', slug: user.get('slug') }
        }

        stripe.customers.create newCustomer, (err, customer) =>
          if err
            if err.type in ['StripeCardError', 'StripeInvalidRequestError']
              return done({res: 'Card error', code: 402})
            else
              @logSubscriptionError(user, 'Stripe customer creation error. '+err)
              return done({res: 'Database error.', code: 500})

          stripeInfo = _.cloneDeep(user.get('stripe') ? {})
          stripeInfo.customerID = customer.id
          user.set('stripe', stripeInfo)
          user.save (err) =>
            if err
              @logSubscriptionError(user, 'Stripe customer id save db error. '+err)
              return done({res: 'Database error.', code: 500})
            @checkForExistingSubscription(req, user, customer, done)

    else
      stripe.customers.retrieve(customerID, (err, customer) =>
        if err
          @logSubscriptionError(user, 'Stripe customer creation error. '+err)
          return done({res: 'Database error.', code: 500})
        @checkForExistingSubscription(req, user, customer, done)
      )


  checkForExistingSubscription: (req, user, customer, done) ->
    couponID = user.get('stripe')?.couponID

    # SALE LOGIC
    # overwrite couponID with another for everyone-sales
    #couponID = 'hoc_399' if not couponID

    if subscription = customer.subscriptions?.data?[0]

      if subscription.cancel_at_period_end
        # Things are a little tricky here. Can't re-enable a cancelled subscription,
        # so it needs to be deleted, but also don't want to charge for the new subscription immediately.
        # So delete the cancelled subscription (no at_period_end given here) and give the new
        # subscription a trial period that ends when the cancelled subscription would have ended.
        stripe.customers.cancelSubscription subscription.customer, subscription.id, (err) =>
          if err
            @logSubscriptionError(user, 'Stripe cancel subscription error. '+err)
            return done({res: 'Database error.', code: 500})

          options = { plan: 'basic', trial_end: subscription.current_period_end }
          options.coupon = couponID if couponID
          stripe.customers.update user.get('stripe').customerID, options, (err, customer) =>
            if err
              @logSubscriptionError(user, 'Stripe customer plan setting error. '+err)
              return done({res: 'Database error.', code: 500})

            @updateUser(req, user, customer, false, done)

      else
        # can skip creating the subscription
        return @updateUser(req, user, customer, false, done)

    else
      options = { plan: 'basic' }
      options.coupon = couponID if couponID
      stripe.customers.update user.get('stripe').customerID, options, (err, customer) =>
        if err
          @logSubscriptionError(user, 'Stripe customer plan setting error. '+err)
          return done({res: 'Database error.', code: 500})

        @updateUser(req, user, customer, true, done)

  updateUser: (req, user, customer, increment, done) ->
    subscription = customer.subscriptions.data[0]
    stripeInfo = _.cloneDeep(user.get('stripe') ? {})
    stripeInfo.planID = 'basic'
    stripeInfo.subscriptionID = subscription.id
    stripeInfo.customerID = customer.id
    req.body.stripe = stripeInfo # to make sure things work for admins, who are mad with power
    user.set('stripe', stripeInfo)

    if increment
      purchased = _.clone(user.get('purchased'))
      purchased ?= {}
      purchased.gems ?= 0
      purchased.gems += subscriptions.basic.gems # TODO: Put actual subscription amount here
      user.set('purchased', purchased)

    user.save (err) =>
      if err
        @logSubscriptionError(user, 'Stripe user plan saving error. '+err)
        return done({res: 'Database error.', code: 500})
      user?.saveActiveUser 'subscribe'
      return done()

  unsubscribeUser: (req, user, done) ->
    stripeInfo = _.cloneDeep(user.get('stripe'))
    stripe.customers.cancelSubscription stripeInfo.customerID, stripeInfo.subscriptionID, { at_period_end: true }, (err) =>
      if err
        @logSubscriptionError(user, 'Stripe cancel subscription error. '+err)
        return done({res: 'Database error.', code: 500})
      delete stripeInfo.planID
      user.set('stripe', stripeInfo)
      req.body.stripe = stripeInfo
      user.save (err) =>
        if err
          @logSubscriptionError(user, 'User save unsubscribe error. '+err)
          return done({res: 'Database error.', code: 500})
          user?.saveActiveUser 'unsubscribe'
        return done()

module.exports = new SubscriptionHandler()
