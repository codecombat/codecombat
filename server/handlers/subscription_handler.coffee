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
StripeUtils = require '../lib/stripe_utils'
moment = require 'moment'
Product = require '../models/Product'
{formatDollarValue} = require '../../app/core/utils'

recipientCouponID = 'free'

class SubscriptionHandler extends Handler
  logSubscriptionError: (user, msg) ->
    log.warn "Subscription Error: #{user.get('slug')} (#{user._id}): '#{msg}'"

  getByRelationship: (req, res, args...) ->
    return @getStripeEvents(req, res) if args[1] is 'stripe_events'
    return @getStripeInvoices(req, res) if args[1] is 'stripe_invoices'
    return @getStripeSubscriptions(req, res) if args[1] is 'stripe_subscriptions'
    return @getSubscribers(req, res) if args[1] is 'subscribers'
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
          unless err
            trimmedSubscription = _.pick(subscription, ['cancel_at_period_end', 'canceled_at', 'customerID', 'start', 'id', 'metadata'])
            stripeSubscriptions.push(trimmedSubscription)
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


module.exports = new SubscriptionHandler()
