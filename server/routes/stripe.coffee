async = require 'async'
config = require '../../server_config'
stripe = require('stripe')(config.stripe.secretKey)
User = require '../users/User'
Payment = require '../payments/Payment'
errors = require '../commons/errors'
mongoose = require 'mongoose'
utils = require '../../app/core/utils'

module.exports.setup = (app) ->
  # Cache customer -> user ID map (increases test perf considerably)
  customerUserMap = {}

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
      return res.send(500, '') if err
      unless invoice.total or invoice.discount?.coupon?.id is 'free'
        # invoices made when trialing, probably given for people who resubscribe after unsubscribing
        return res.send(200, '')
      return res.send(200, '') unless invoice.lines?.data?.length > 0

      getUserID invoice.customer, (err, userID) =>
        return res.send(500, '') if err

        # User is recipient if no metadata.id
        recipientID = invoice.lines.data[0].metadata?.id or userID

        # Subscription id location depends on invoice line_item type
        subscriptionID = invoice.lines.data[0].subscription or invoice.lines.data[0].id

        User.findById recipientID, (err, recipient) =>
          return res.send(500, '') if err
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
            payment.set 'gems', 3500 if invoice.lines.data[0].plan?.id is 'basic'

            payment.save (err) =>
              return res.send(500, '') if err
              return res.send(201, '') if invoice.lines.data[0].plan?.id isnt 'basic'

              # Update purchased gems
              # TODO: is this correct for a resub?
              Payment.find({recipient: recipient._id, gems: {$exists: true}}).select('gems').exec (err, payments) ->
                gems = _.reduce payments, ((sum, p) -> sum + p.get('gems')), 0
                purchased = _.clone(recipient.get('purchased'))
                purchased ?= {}
                purchased.gems = gems
                recipient.set('purchased', purchased)
                recipient.save (err) ->
                  return res.send(500, '') if err
                  return res.send(201, '')

  handleSubscriptionDeleted = (req, res) ->
    # Three variants:
    # normal - Personal subscription deleted
    # recipeint - Subscription sponsored by another user is being deleted.
    # sponsor - Aggregate subscription used to pay for multiple recipient subscriptions.  Ugh.

    subscription = req.body.data.object

    checkNormalSubscription = (done) ->
      User.findOne {'stripe.subscriptionID': subscription.id}, (err, user) ->
        return done() unless user

        stripeInfo = _.cloneDeep(user.get('stripe') ? {})
        delete stripeInfo.planID
        delete stripeInfo.prepaidCode
        delete stripeInfo.subscriptionID
        user.set('stripe', stripeInfo)
        user.save (err) =>
          return res.send(500, '') if err
          return res.send(200, '')

    checkRecipientSubscription = (done) ->
      return done() unless subscription.plan.id is 'basic'
      User.findById subscription.metadata.id, (err, recipient) =>
        return res.send(500, '') if err
        return res.send(500, '') unless recipient
        User.findById recipient.get('stripe').sponsorID, (err, sponsor) =>
          return res.send(500, '') if err
          return res.send(500, '') unless sponsor

          # Update sponsor subscription
          stripeInfo = _.cloneDeep(sponsor.get('stripe') ? {})
          _.remove(stripeInfo.recipients, (s) -> s.userID is recipient.id)
          options =
            quantity: utils.getSponsoredSubsAmount(subscription.plan.amount, stripeInfo.recipients.length, stripeInfo.subscriptionID?)
          stripe.customers.updateSubscription stripeInfo.customerID, stripeInfo.sponsorSubscriptionID, options, (err, subscription) =>
            return res.send(500, '') if err

            # Update sponsor user
            sponsor.set 'stripe', stripeInfo
            sponsor.save (err) =>
              return res.send(500, '') if err

              # Update recipient user
              stripeInfo = recipient.get('stripe')
              delete stripeInfo.sponsorID
              if _.isEmpty stripeInfo
                recipient.set 'stripe', undefined
              else
                recipient.set 'stripe', stripeInfo
              recipient.save (err) =>
                return res.send(500, '') if err
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
          return res.send(500, '') if err

          # Update sponsor user
          delete stripeInfo.sponsorSubscriptionID
          delete stripeInfo.recipients # Loses remaining credit on a re-subscribe for previous user
          if _.isEmpty stripeInfo
            sponsor.set 'stripe', undefined
          else
            sponsor.set 'stripe', stripeInfo
          sponsor.save (err) =>
            return res.send(500, '') if err
            done()

    # TODO: use async.series for this
    checkNormalSubscription ->
      checkRecipientSubscription ->
        checkSponsorSubscription ->
          res.send(200, '')
