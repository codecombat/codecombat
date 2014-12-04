# Not paired with a document in the DB, just handles coordinating between
# the stripe property in the user with what's being stored in Stripe.

Handler = require '../commons/Handler'
config = require '../../server_config'
stripe = require('stripe')(config.stripe.secretKey)

subscriptions = {
  basic: {
    gems: 3500
  }
}

class SubscriptionHandler extends Handler
  logSubscriptionError: (req, msg) ->
    console.warn "Subscription Error: #{req.user.get('slug')} (#{req.user._id}): '#{msg}'"

  subscribeUser: (req, user, done) ->
    stripeToken = req.body.stripe?.token
    extantCustomerID = user.get('stripe')?.customerID
    if not (stripeToken or extantCustomerID)
      @logSubscriptionError(req, 'Missing stripe token or customer ID.')
      return done({res: 'Missing stripe token or customer ID.', code: 422})

    if stripeToken
      stripe.customers.create({
        card: stripeToken
        email: req.user.get('email')
        metadata: {
          id: req.user._id + ''
          slug: req.user.get('slug')
        }
      }).then(((customer) =>
          stripeInfo = _.cloneDeep(req.user.get('stripe') ? {})
          stripeInfo.customerID = customer.id
          req.user.set('stripe', stripeInfo)
          req.user.save((err) =>
            if err
              @logSubscriptionError(req, 'Stripe customer id save db error. '+err)
              return done({res: 'Database error.', code: 500})
            @checkForExistingSubscription(req, user, customer, done)
          )
        ),
      (err) =>
        if err.type in ['StripeCardError', 'StripeInvalidRequestError']
          done({res: 'Card error', code: 402})
        else
          @logSubscriptionError(req, 'Stripe customer creation error. '+err)
          return done({res: 'Database error.', code: 500})
      )

    else
      stripe.customers.retrieve(extantCustomerID, (err, customer) =>
        if err
          @logSubscriptionError(req, 'Stripe customer creation error. '+err)
          return done({res: 'Database error.', code: 500})
        else if not customer
          # TODO: what actually happens when you try to retrieve a customer and it DNE?
          @logSubscriptionError(req, 'Stripe customer id is missing! '+err)
          stripeInfo = _.cloneDeep(req.user.get('stripe') ? {})
          delete stripeInfo.customerID
          req.user.set('stripe', stripeInfo)
          req.user.save (err) =>
            if err
              @logSubscriptionError(req, 'Stripe customer id delete db error. '+err)
              return done({res: 'Database error.', code: 500})
            @subscribeUser(req, done)
        else
          @checkForExistingSubscription(req, user, customer, done)
      )


  checkForExistingSubscription: (req, user, customer, done) ->
    if subscription = customer.subscriptions?.data?[0]

      if subscription.cancel_at_period_end
        # Things are a little tricky here. Can't re-enable a cancelled subscription,
        # so it needs to be deleted, but also don't want to charge for the new subscription immediately.
        # So delete the cancelled subscription (no at_period_end given here) and give the new
        # subscription a trial period that ends when the cancelled subscription would have ended.
        stripe.customers.cancelSubscription subscription.customer, subscription.id, (err) =>
          if err
            @logSubscriptionError(req, 'Stripe cancel subscription error. '+err)
            return done({res: 'Database error.', code: 500})

          options = { plan: 'basic', trial_end: subscription.current_period_end }
          stripe.customers.update req.user.get('stripe').customerID, options, (err, customer) =>
            if err
              @logSubscriptionError(req, 'Stripe customer plan setting error. '+err)
              return done({res: 'Database error.', code: 500})

            @updateUser(req, user, customer.subscriptions.data[0], false, done)

      else
        # can skip creating the subscription
        return @updateUser(req, user, customer.subscriptions.data[0], false, done)

    else
      stripe.customers.update req.user.get('stripe').customerID, { plan: 'basic' }, (err, customer) =>
        if err
          @logSubscriptionError(req, 'Stripe customer plan setting error. '+err)
          return done({res: 'Database error.', code: 500})

        @updateUser(req, user, customer.subscriptions.data[0], true, done)


  updateUser: (req, user, subscription, increment, done) ->
    stripeInfo = _.cloneDeep(user.get('stripe') ? {})
    stripeInfo.planID = 'basic'
    stripeInfo.subscriptionID = subscription.id
    stripeInfo.customerID = subscription.customer
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
        @logSubscriptionError(req, 'Stripe user plan saving error. '+err)
        return done({res: 'Database error.', code: 500})
      return done()


  unsubscribeUser: (req, user, done) ->
    stripeInfo = _.cloneDeep(user.get('stripe'))
    stripe.customers.cancelSubscription stripeInfo.customerID, stripeInfo.subscriptionID, { at_period_end: true }, (err) =>
      if err
        @logSubscriptionError(req, 'Stripe cancel subscription error. '+err)
        return done({res: 'Database error.', code: 500})
      delete stripeInfo.planID
      user.set('stripe', stripeInfo)
      req.body.stripe = stripeInfo
      user.save (err) =>
        if err
          @logSubscriptionError(req, 'User save unsubscribe error. '+err)
          return done({res: 'Database error.', code: 500})
        return done()


module.exports = new SubscriptionHandler()
