async = require 'async'
config = require '../../server_config'
stripe = require('stripe')(config.stripe.secretKey)
User = require '../models/User'
Payment = require '../models/Payment'
errors = require '../commons/errors'
mongoose = require 'mongoose'
utils = require '../../app/core/utils'

module.exports.setup = (app) ->
  # Cache customer -> user ID map (increases test perf considerably)
  customerUserMap = {}

  logStripeWebhookError = (msg) ->
    console.warn "Stripe Webhook Error: #{msg}"

  app.post '/stripe/webhook', (req, res) ->

    # Subscription renewal events:
    # https://support.stripe.com/questions/what-events-can-i-see-when-a-subscription-is-renewed

    if req.body.type is 'invoice.payment_succeeded'
      return handlePaymentSucceeded req, res
    else if req.body.type is 'customer.subscription.deleted'
      return handleSubscriptionDeleted req, res
    else # ignore all other notifications
      return res.send(200, '')

  app.get '/stripe/coupons', (req, res) ->
    return errors.forbidden(res) unless req.user?.isAdmin()
    stripe.coupons.list {limit: 100}, (err, coupons) ->
      return errors.serverError(res) if err
      res.send(200, coupons.data)
      return res.end()

  handlePaymentSucceeded = (req, res) ->
    # if they actually paid, give em some gems

    getUserID = (customerID, done) =>
      # Asumming Stripe customer never has a different userID
      return done(null, customerUserMap[customerID]) if customerID of customerUserMap
      stripe.customers.retrieve customerID, (err, customer) =>
        return done(err) if err
        customerUserMap[customerID] = customer.metadata.id
        return done(null, customerUserMap[customerID])

    invoiceID = req.body.data.object.id
    stripe.invoices.retrieve invoiceID, (err, invoice) =>
      if err
        logStripeWebhookError("Retrieve invoice error: #{JSON.stringify(err)}")
        return res.send(500, '')
      unless invoice.total or invoice.discount?.coupon?.id in ['free', 'brazil']
        # invoices made when trialing, probably given for people who resubscribe after unsubscribing
        # also I can't change the test-mode brazil coupon to not end up with a zero price now
        return res.send(200, '')
      return res.send(200, '') unless invoice.lines?.data?.length > 0

      getUserID invoice.customer, (err, userID) =>
        if err
          logStripeWebhookError("Get user ID error: #{JSON.stringify(err)}")
          return res.send(500, '')

        # User is recipient if no metadata.id
        recipientID = invoice.lines.data[0].metadata?.id or userID

        # Subscription id location depends on invoice line_item type
        subscriptionID = invoice.lines.data[0].subscription or invoice.lines.data[0].id

        User.findById recipientID, (err, recipient) =>
          if err
            logStripeWebhookError("Find recipient user error: #{JSON.stringify(err)}")
            return res.send(500, '')
          return res.send(200) unless recipient # just for the sake of testing...

          Payment.findOne {'stripe.invoiceID': invoiceID}, (err, payment) =>
            return res.send(200, '') if payment
            payment = new Payment({
              'purchaser': mongoose.Types.ObjectId(userID)
              'recipient': recipient._id
              'created': new Date().toISOString()
              'service': 'stripe'
              'amount': invoice.total
              'stripe': {
                customerID: invoice.customer
                invoiceID: invoice.id
                subscriptionID: subscriptionID
              }
            })
            # TODO: load gems from correct Product
            productGems = 3500
            if recipient.get('country') is 'brazil'
              productGems = 1500
            payment.set 'gems', productGems if invoice.lines.data[0].plan?.id is 'basic'

            payment.save (err) =>
              if err
                logStripeWebhookError("Save payment error: #{JSON.stringify(err)}")
                return res.send(500, '')
              return res.send(201, '') if invoice.lines.data[0].plan?.id isnt 'basic'

              # Update purchased gems
              # TODO: is this correct for a resub?
              Payment.find({recipient: recipient._id, gems: {$exists: true}}).select('gems').exec (err, payments) ->
                gems = _.reduce payments, ((sum, p) -> sum + (p.get('gems') or 0)), 0
                purchased = _.clone(recipient.get('purchased'))
                purchased ?= {}
                purchased.gems = gems
                recipient.set('purchased', purchased)
                recipient.save (err) ->
                  if err
                    logStripeWebhookError("Save recipient user error: #{JSON.stringify(err)}")
                    return res.send(500, '')
                  return res.send(201, '')

  handleSubscriptionDeleted = (req, res) ->
    # Three variants:
    # normal - Personal subscription deleted
    # recipeint - Subscription sponsored by another user is being deleted.
    # sponsor - Aggregate subscription used to pay for multiple recipient subscriptions.  Ugh.

    subscription = req.body.data.object

    checkUserExists = (done) ->
      stripe.customers.retrieve subscription.customer, (err, customer) =>
        if err
          logStripeWebhookError("Failed to retrieve #{subscription.customer}")
          return res.send(500, '')
        unless customer?.metadata?.id
          logStripeWebhookError("Customer with no metadata.id #{subscription.customer}")
          return res.send(500, '')
        User.findById customer.metadata.id, (err, user) =>
          if err
            logStripeWebhookError(err)
            return res.send(500, '')
          unless user
            logStripeWebhookError("User not found #{customer.metadata.id}")
            return res.send(500, '')
          return res.send(200, '') if user.get('deleted') is true
          done()

    checkNormalSubscription = (done) ->
      User.findOne {'stripe.subscriptionID': subscription.id}, (err, user) ->
        return done() unless user

        stripeInfo = _.cloneDeep(user.get('stripe') ? {})
        delete stripeInfo.planID
        delete stripeInfo.prepaidCode
        delete stripeInfo.subscriptionID
        user.set('stripe', stripeInfo)
        user.save (err) =>
          if err
            logStripeWebhookError(err)
            return res.send(500, '')
          return res.send(200, '')

    checkRecipientSubscription = (done) ->
      return done() unless subscription.plan.id is 'basic'
      return done() unless subscription.metadata?.id # Shouldn't be possible

      deleteUserStripeProp = (user, propName) ->
        stripeInfo = _.cloneDeep(user.get('stripe') ? {})
        delete stripeInfo[propName]
        if _.isEmpty stripeInfo
          user.set 'stripe', undefined
        else
          user.set 'stripe', stripeInfo

      User.findById subscription.metadata.id, (err, recipient) =>
        if err
          logStripeWebhookError(err)
          return res.send(500, '')
        unless recipient
          logStripeWebhookError("Recipient not found #{subscription.metadata.id}")
          return res.send(500, '')

        # Recipient cancellations are immediate, no work to perform if recipient's sponsorID is already gone
        return res.send(200, '') unless recipient.get('stripe')?.sponsorID?

        User.findById recipient.get('stripe').sponsorID, (err, sponsor) =>
          if err
            logStripeWebhookError(err)
            return res.send(500, '')
          unless sponsor
            logStripeWebhookError("Sponsor not found #{recipient.get('stripe').sponsorID}")
            return res.send(500, '')

          # Update sponsor subscription
          stripeInfo = _.cloneDeep(sponsor.get('stripe') ? {})
          stripeInfo.recipients ?= []

          if stripeInfo.sponsorSubscriptionID
            _.remove(stripeInfo.recipients, (s) -> s.userID is recipient.id)
            options =
              quantity: utils.getSponsoredSubsAmount(subscription.plan.amount, stripeInfo.recipients.length, stripeInfo.subscriptionID?)
            stripe.customers.updateSubscription stripeInfo.customerID, stripeInfo.sponsorSubscriptionID, options, (err, subscription) =>
              if err
                logStripeWebhookError(err)
                return res.send(500, '')

              # Update sponsor user
              sponsor.set 'stripe', stripeInfo
              sponsor.save (err) =>
                if err
                  logStripeWebhookError(err)
                  return res.send(500, '')

                # Update recipient user
                deleteUserStripeProp recipient, 'sponsorID'
                recipient.save (err) =>
                  if err
                    logStripeWebhookError(err)
                    return res.send(500, '')
                  return res.send(200, '')
          else
            # Remove sponsorships from sponsor and recipients
            console.error "Couldn't find sponsorSubscriptionID from stripeInfo", stripeInfo, 'for customer', stripeInfo.customerID, 'with options', options, 'and subscription', subscription, 'for user', recipient.id, 'with sponsor', sponsor.id

            # Update recipients
            createUpdateFn = (recipientID) ->
              (callback) ->
                User.findById recipientID, (err, recipient) =>
                  if err
                    logStripeWebhookError(err)
                    return callback(err)

                  deleteUserStripeProp recipient, 'sponsorID'
                  recipient.save (err) =>
                    logStripeWebhookError(err) if err
                    callback(err)
            async.parallel (createUpdateFn(recipient.userID) for recipient in stripeInfo.recipients), (err, results) =>
              if err
                logStripeWebhookError(err)
                return res.send(500, '')

              # Update sponsor
              deleteUserStripeProp sponsor, 'recipients'
              sponsor.save (err) =>
                if err
                  logStripeWebhookError(err)
                  return res.send(500, '')
                return res.send(200, '')

    checkSponsorSubscription = (done) ->
      return done() unless subscription.plan.id is 'incremental'

      customerID = subscription.customer

      createUpdateFn = (sub) ->
        (callback) ->
          # Cancel Stripe recipient subscription
          stripe.customers.cancelSubscription customerID, sub.subscriptionID, { at_period_end: true }, (err) ->
            callback err

      User.findById subscription.metadata.id, (err, sponsor) =>
        return res.send(500, '') if err
        stripeInfo = _.cloneDeep(sponsor.get('stripe') ? {})

        # Cancel all recipient subscriptions
        async.parallel (createUpdateFn(sub) for sub in stripeInfo.recipients), (err, results) =>
          if err
            logStripeWebhookError(err)
            return res.send(500, '')

          # Update sponsor user
          delete stripeInfo.sponsorSubscriptionID
          delete stripeInfo.recipients # Loses remaining credit on a re-subscribe for previous user
          if _.isEmpty stripeInfo
            sponsor.set 'stripe', undefined
          else
            sponsor.set 'stripe', stripeInfo
          sponsor.save (err) =>
            if err
              logStripeWebhookError(err)
              return res.send(500, '')
            done()

    # TODO: use async.series for this
    checkUserExists ->
      checkNormalSubscription ->
        checkRecipientSubscription ->
          checkSponsorSubscription ->
            res.send(200, '')
