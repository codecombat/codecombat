async = require 'async'
config = require '../../../server_config'
require '../common'
appUtils = require '../../../app/core/utils' # Must come after require /common
utils = require '../utils'
mongoose = require 'mongoose'
TRAVIS = process.env.COCO_TRAVIS_TEST
nockUtils = require '../nock-utils'
User = require '../../../server/models/User'
Payment = require '../../../server/models/Payment'
Prepaid = require '../../../server/models/Prepaid'
Product = require '../../../server/models/Product'
request = require '../request'
libUtils = require '../../../server/lib/utils'
moment = require 'moment'
middleware = require '../../../server/middleware'
errors = require '../../../server/commons/errors'
winston = require 'winston'
paypal = require '../../../server/lib/paypal'

subPrice = 100
subGems = 3500
subGemsBrazil = 1500

# sample data that comes in through the webhook when you subscribe
invoiceChargeSampleEvent = {
  id: 'evt_155TBeKaReE7xLUdrKM72O5R',
  created: 1417574898,
  livemode: false,
  type: 'invoice.payment_succeeded',
  data: {
    object: {
      date: 1417574897,
      id: 'in_155TBdKaReE7xLUdv8z8ipWl',
      period_start: 1417574897,
      period_end: 1417574897,
      lines: {},
      subtotal: 100,
      total: 100,
      customer: 'cus_5Fz9MVWP2bDPGV',
      object: 'invoice',
      attempted: true,
      closed: true,
      forgiven: false,
      paid: true,
      livemode: false,
      attempt_count: 1,
      amount_due: 100,
      currency: 'usd',
      starting_balance: 0,
      ending_balance: 0,
      next_payment_attempt: null,
      webhooks_delivered_at: null,
      charge: 'ch_155TBdKaReE7xLUdRU0WcMzR',
      discount: null,
      application_fee: null,
      subscription: 'sub_5Fz99gXrBtreNe',
      metadata: {},
      statement_description: null,
      description: null,
      receipt_number: null
    }
  },
  object: 'event',
  pending_webhooks: 1,
  request: 'iar_5Fz9c4BZJyNNsM',
  api_version: '2015-02-18'
}

customerSubscriptionDeletedSampleEvent = {
  id: 'evt_155Tj4KaReE7xLUdpoMx0UaA',
  created: 1417576970,
  livemode: false,
  type: 'customer.subscription.deleted',
  data: {
    object: {
      id: 'sub_5FziOkege03vT7',
      plan: [Object],
      object: 'subscription',
      start: 1417576967,
      status: 'canceled',
      customer: 'cus_5Fzi54gMvGG9Px',
      cancel_at_period_end: true,
      current_period_start: 1417576967,
      current_period_end: 1420255367,
      ended_at: 1417576970,
      trial_start: null,
      trial_end: null,
      canceled_at: 1417576970,
      quantity: 1,
      application_fee_percent: null,
      discount: null,
      metadata: {}
    }
  },
  object: 'event',
  pending_webhooks: 1,
  request: 'iar_5FziYQJ4oQdL6w',
  api_version: '2015-02-18'
}


describe '/db/user, editing stripe property', ->
  beforeEach utils.wrap (done) ->
    yield utils.populateProducts()
    done()
  afterEach nockUtils.teardownNock

  stripe = require('stripe')(config.stripe.secretKey)
  userURL = getURL('/db/user')
  webhookURL = getURL('/stripe/webhook')
  headers = {'X-Change-Plan': 'true'}

  it 'clears the db first', (done) ->
    clearModels [User, Payment], (err) ->
      throw err if err
      resetUserIDCounter(100000) # because fixtures depend on dependable user ids
      done()

  it 'denies anonymous users trying to subscribe', (done) ->
    request.get getURL('/auth/whoami'), (err, res, body) ->
      body = JSON.parse(body)
      body.stripe = { planID: 'basic', token: '12345' }
      request.put {uri: userURL, json: body, headers: headers}, (err, res, body) ->
        expect(res.statusCode).toBe 401
        done()

  #- shared data between tests
  joeData = null
  firstSubscriptionID = null

  describe 'glue between PUT /db/user handler and subscriptions.subscribeUser middleware', ->
    beforeEach utils.wrap ->
      user = yield utils.initUser()
      yield utils.loginUser(user)
      @json = user.toObject()
      @json.stripe = { planID: 'basic' }
      @url = userURL

    describe 'when subscriptions.subscribeUser throws a NetworkError subclass', ->
      beforeEach ->
        spyOn(middleware.subscriptions, 'subscribeUser')
        .and.returnValue(Promise.reject(new errors.Forbidden('Forbidden!')))

      it 'returns the thrown network error', utils.wrap ->
        [res, body] = yield request.putAsync { @url, @json, headers }
        expect(res.statusCode).toBe(403)
        expect(res.body).toBe('Forbidden!')

    describe 'when subscriptions.subscribeUser returns a legacy error object', ->
      beforeEach ->
        spyOn(middleware.subscriptions, 'subscribeUser')
        .and.returnValue(Promise.reject({ res: 'test', code: 444 }))

      it 'returns the thrown error', utils.wrap ->
        [res, body] = yield request.putAsync { @url, @json, headers }
        expect(res.statusCode).toBe(444)
        expect(res.body).toBe('test')


    describe 'when subscriptions.subscribeUser returns an error with "declined" in the message', ->
      beforeEach ->
        spyOn(middleware.subscriptions, 'subscribeUser')
        .and.returnValue(Promise.reject(new Error('Your card was declined.')))

      it 'returns 500', utils.wrap ->
        spyOn(winston, 'warn')
        [res, body] = yield request.putAsync { @url, @json, headers }
        expect(res.statusCode).toBe(402)
        expect(res.body).toBe('Card declined')
        expect(winston.warn).not.toHaveBeenCalled()

    describe 'when subscriptions.subscribeUser returns a runtime error', ->
      beforeEach ->
        spyOn(middleware.subscriptions, 'subscribeUser')
        .and.returnValue(Promise.reject(new Error('Something went terribly awry!')))

      it 'returns 500', utils.wrap ->
        spyOn(winston, 'warn')
        [res, body] = yield request.putAsync { @url, @json, headers }
        expect(res.statusCode).toBe(500)
        expect(res.body).toBe('Subscription error.')
        expect(winston.warn).toHaveBeenCalled()

  describe 'glue between PUT /db/user handler and subscriptions.unsubscribeUser middleware', ->
    beforeEach utils.wrap ->
      user = yield utils.initUser({stripe: {planID: 'basic'}})
      yield utils.loginUser(user)
      @json = _.clone(user.toObject())
      @json.stripe = {}
      @url = userURL

    describe 'when subscriptions.unsubscribeUser throws a NetworkError subclass', ->
      beforeEach ->
        spyOn(middleware.subscriptions, 'unsubscribeUser')
        .and.returnValue(Promise.reject(new errors.Forbidden('Forbidden!')))

      it 'returns the thrown network error', utils.wrap ->
        [res, body] = yield request.putAsync { @url, @json, headers }
        expect(res.statusCode).toBe(403)
        expect(res.body).toBe('Forbidden!')

    describe 'when subscriptions.unsubscribeUser returns a legacy error object', ->
      beforeEach ->
        spyOn(middleware.subscriptions, 'unsubscribeUser')
        .and.returnValue(Promise.reject({ res: 'test', code: 444 }))

      it 'returns the thrown error', utils.wrap ->
        [res, body] = yield request.putAsync { @url, @json, headers }
        expect(res.statusCode).toBe(444)
        expect(res.body).toBe('test')

    describe 'when subscriptions.unsubscribeUser returns a runtime error', ->
      beforeEach ->
        spyOn(middleware.subscriptions, 'unsubscribeUser')
        .and.returnValue(Promise.reject(new Error('Something went terribly awry!')))

      it 'returns 500', utils.wrap ->
        spyOn(winston, 'warn')
        [res, body] = yield request.putAsync { @url, @json, headers }
        expect(res.statusCode).toBe(500)
        expect(res.body).toBe('Subscription error.')
        expect(winston.warn).toHaveBeenCalled()


  it 'returns client error when a token fails to charge', (done) ->
    nockUtils.setupNock 'db-user-sub-test-1.json', (err, nockDone) ->
      stripe.tokens.create {
        card: { number: '4000000000000002', exp_month: 12, exp_year: 2020, cvc: '123' }
      }, (err, token) ->
        stripeTokenID = token.id
        loginJoe (joe) ->
          joeData = joe.toObject()
          joeData.stripe = {
            token: stripeTokenID
            planID: 'basic'
          }
          request.put {uri: userURL, json: joeData, headers: headers }, (err, res, body) ->
            expect(res.statusCode).toBe(402)
            nockDone()
            done()

  it 'creates a subscription when you put a token and plan', (done) ->
    nockUtils.setupNock 'db-user-sub-test-2.json', (err, nockDone) ->
      stripe.tokens.create {
        card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
      }, (err, token) ->
        stripeTokenID = token.id
        loginJoe (joe) ->
          joeData = joe.toObject()
          joeData.stripe = {
            token: stripeTokenID
            planID: 'basic'
          }
          request.put {uri: userURL, json: joeData, headers: headers }, (err, res, body) ->
            joeData = body
            expect(res.statusCode).toBe(200)
            expect(joeData.purchased.gems).toBe(subGems)
            expect(joeData.stripe.customerID).toBeDefined()
            expect(firstSubscriptionID = joeData.stripe.subscriptionID).toBeDefined()
            expect(joeData.stripe.planID).toBe('basic')
            expect(joeData.stripe.token).toBeUndefined()
            nockDone()
            done()

  it 'records a payment through the webhook', (done) ->
    nockUtils.setupNock 'db-user-sub-test-3.json', (err, nockDone) ->
      # Don't even want to think about hooking in tests to webhooks, so... put in some data manually
      stripe.invoices.list {customer: joeData.stripe.customerID}, (err, invoices) ->
        expect(invoices.data.length).toBe(1)
        event = _.cloneDeep(invoiceChargeSampleEvent)
        event.data.object = invoices.data[0]

        request.post {uri: webhookURL, json: event}, (err, res, body) ->
          expect(res.statusCode).toBe(201)
          Payment.find {}, (err, payments) ->
            expect(payments.length).toBe(1)
            User.findById joeData._id, (err, user) ->
              expect(user.get('purchased').gems).toBe(subGems)
              nockDone()
              done()

  it 'schedules the stripe subscription to be cancelled when stripe.planID is removed from the user', (done) ->
    nockUtils.setupNock 'db-user-sub-test-4.json', {keep: {cancel_at_period_end: true}}, (err, nockDone) ->
      delete joeData.stripe.planID
      request.put {uri: userURL, json: joeData, headers: headers }, (err, res, body) ->
        joeData = body
        expect(res.statusCode).toBe(200)
        expect(joeData.stripe.subscriptionID).toBeDefined()
        expect(joeData.stripe.planID).toBeUndefined()
        expect(joeData.stripe.customerID).toBeDefined()
        stripe.customers.retrieve joeData.stripe.customerID, (err, customer) ->
          expect(customer.subscriptions.data.length).toBe(1)
          expect(customer.subscriptions.data[0].cancel_at_period_end).toBe(true)
          nockDone()
          done()

  it 'allows you to sign up again using the same customer ID as before, no token necessary', (done) ->
    nockUtils.setupNock 'db-user-sub-test-5.json', (err, nockDone) ->
      joeData.stripe.planID = 'basic'
      request.put {uri: userURL, json: joeData, headers: headers }, (err, res, body) ->
        joeData = body

        expect(res.statusCode).toBe(200)
        expect(joeData.stripe.customerID).toBeDefined()
        expect(joeData.stripe.subscriptionID).toBeDefined()
        expect(joeData.stripe.subscriptionID).not.toBe(firstSubscriptionID)
        expect(joeData.stripe.planID).toBe('basic')
        nockDone()
        done()

  it 'will not have immediately created new payments when signing back up from a cancelled subscription', (done) ->
    nockUtils.setupNock 'db-user-sub-test-6.json', (err, nockDone) ->
      stripe.invoices.list {customer: joeData.stripe.customerID}, (err, invoices) ->
        expect(invoices.data.length).toBe(2)
        expect(invoices.data[0].total).toBe(0)
        event = _.cloneDeep(invoiceChargeSampleEvent)
        event.data.object = invoices.data[0]

        request.post {uri: webhookURL, json: event}, (err, res, body) ->
          expect(res.statusCode).toBe(200)
          Payment.find {}, (err, payments) ->
            expect(payments.length).toBe(1)
            User.findById joeData._id, (err, user) ->
              expect(user.get('purchased').gems).toBe(subGems)
              nockDone()
              done()

  it 'deletes the subscription from the user object when an event about it comes through the webhook', (done) ->
    nockUtils.setupNock 'db-user-sub-test-7.json', (err, nockDone) ->
      stripe.customers.retrieveSubscription joeData.stripe.customerID, joeData.stripe.subscriptionID, (err, subscription) ->
        event = _.cloneDeep(customerSubscriptionDeletedSampleEvent)
        event.data.object = subscription
        request.post {uri: webhookURL, json: event}, (err, res, body) ->
          User.findById joeData._id, (err, user) ->
            expect(user.get('purchased').gems).toBe(subGems)
            expect(user.get('stripe').subscriptionID).toBeUndefined()
            expect(user.get('stripe').planID).toBeUndefined()
            nockDone()
            done()

  it "updates the customer's email when you change the user's email", (done) ->
    nockUtils.setupNock 'db-user-sub-test-8.json', {keep: {email: true}}, (err, nockDone) ->
      joeData.email = 'newEmail@gmail.com'
      request.put {uri: userURL, json: joeData, headers: headers }, (err, res, body) ->
        f = -> stripe.customers.retrieve joeData.stripe.customerID, (err, customer) ->
          expect(customer.email).toBe('newEmail@gmail.com')
          nockDone()
          done()
        setTimeout(f, 500) # bit of a race condition here, response returns before stripe has been updated


describe 'Subscriptions', ->
  # TODO: Test recurring billing via webhooks
  # TODO: Test error rollbacks, Stripe is authority

  stripe = require('stripe')(config.stripe.secretKey)
  userURL = getURL('/db/user')
  webhookURL = getURL('/stripe/webhook')
  headers = {'X-Change-Plan': 'true'}
  invoicesWebHooked = {}
  beforeEach utils.wrap (done) ->
    yield utils.populateProducts()
    done()
  afterEach nockUtils.teardownNock

  # Start helpers

  subscribeUser = (user, token, prepaidCode, done) ->
    requestBody = user.toObject()
    requestBody.stripe =
      planID: 'basic'
    requestBody.stripe.token = token.id if token?
    requestBody.stripe.prepaidCode = prepaidCode if prepaidCode?
    request.put {uri: userURL, json: requestBody, headers: headers }, (err, res, body) ->
      expect(err).toBeNull()
      return done() if err
      expect(res.statusCode).toBe(200)
      expect(body.stripe).toBeDefined()
      return done() unless body.stripe
      expect(body.stripe.customerID).toBeDefined()
      expect(body.stripe.planID).toBe('basic')
      expect(body.stripe.token).toBeUndefined()
      if prepaidCode?
        expect(body.stripe.prepaidCode).toEqual(prepaidCode)
        expect(body.stripe.couponID).toEqual('free')
      expect(body.purchased.gems).toBeGreaterThan(subGems - 1)
      User.findById user.id, (err, user) ->
        stripeInfo = user.get('stripe')
        expect(stripeInfo.customerID).toBeDefined()
        expect(stripeInfo.planID).toBe('basic')
        expect(stripeInfo.token).toBeUndefined()
        if prepaidCode?
          expect(stripeInfo.prepaidCode).toEqual(prepaidCode)
          expect(stripeInfo.couponID).toEqual('free')
        expect(user.get('purchased').gems).toBeGreaterThan(subGems - 1)
      done()

  unsubscribeUser = (user, done) ->
    requestBody = user.toObject()
    delete requestBody.stripe.planID
    delete requestBody.stripe.prepaidCode
    request.put {uri: userURL, json: requestBody, headers: headers }, (err, res, body) ->
      expect(err).toBeNull()
      expect(res.statusCode).toBe(200)
      User.findById user.id, (err, user) ->
        expect(user.get('stripe').customerID).toBeDefined()
        expect(user.get('stripe').planID).toBeUndefined()
        expect(user.get('stripe').token).toBeUndefined()
        expect(user.get('stripe').subscriptionID).toBeDefined()
        return done() unless user.get('stripe').subscriptionID
        stripe.customers.retrieveSubscription user.get('stripe').customerID, user.get('stripe').subscriptionID, (err, subscription) ->
          expect(err).toBeNull()
          expect(subscription).not.toBeNull()
          expect(subscription?.cancel_at_period_end).toEqual(true)
          done()

  # End helpers


  # TODO: Use beforeAll()
  it 'Clear database users and payments', (done) ->
    clearModels [User, Payment], (err) ->
      throw err if err
      done()

  describe 'Personal', ->
    it 'Subscribe user with new token', (done) ->
      nockUtils.setupNock 'sub-test-01.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            subscribeUser user1, token, null, ->
              nockDone()
              done()

    it 'User delete unsubscribes', (done) ->
      nockUtils.setupNock 'sub-test-02.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            subscribeUser user1, token, null, ->
              User.findById user1.id, (err, user1) ->
                expect(err).toBeNull()
                customerID = user1.get('stripe').customerID
                subscriptionID = user1.get('stripe').subscriptionID
                stripe.customers.retrieveSubscription customerID, subscriptionID, (err, subscription) ->
                  expect(err).toBeNull()
                  expect(subscription?.cancel_at_period_end).toEqual(false)
                  request.del {uri: "#{userURL}/#{user1.id}"}, (err, res) ->
                    expect(err).toBeNull()
                    stripe.customers.retrieveSubscription customerID, subscriptionID, (err, subscription) ->
                      expect(err).toBeNull()
                      expect(subscription?.cancel_at_period_end).toEqual(true)
                      nockDone()
                      done()

    it 'User subscribes, deletes themselves, subscription ends', (done) ->
      nockUtils.setupNock 'sub-test-03.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            # Subscribe user
            subscribeUser user1, token, null, ->
              User.findById user1.id, (err, user1) ->
                expect(err).toBeNull()
                customerID = user1.get('stripe').customerID
                subscriptionID = user1.get('stripe').subscriptionID
                stripe.customers.retrieveSubscription customerID, subscriptionID, (err, subscription) ->
                  expect(err).toBeNull()
                  expect(subscription).not.toBeNull()
                  # Delete user
                  request.del {uri: "#{userURL}/#{user1.id}"}, (err, res) ->
                    expect(err).toBeNull()
                    # Simulate Stripe subscription deleted via webhook
                    event = _.cloneDeep(customerSubscriptionDeletedSampleEvent)
                    event.data.object = subscription
                    request.post {uri: webhookURL, json: event}, (err, res, body) ->
                      expect(err).toBeNull()
                      expect(res.statusCode).toEqual(200)
                      nockDone()
                      done()

    it 'Subscribe with prepaid, then delete', (done) ->
      nockUtils.setupNock 'sub-test-04.json', (err, nockDone) ->
        loginNewUser (user1) ->
          user1.set('permissions', ['admin'])
          user1.save (err, user1) ->
            expect(err).toBeNull()
            expect(user1.isAdmin()).toEqual(true)
            createPrepaid 'subscription', 1, 0, (err, res, prepaid) ->
              expect(err).toBeNull()
              subscribeUser user1, null, prepaid.code, ->
                Prepaid.findById prepaid._id, (err, prepaid) ->
                  expect(err).toBeNull()
                  expect(prepaid.get('maxRedeemers')).toEqual(1)
                  expect(prepaid.get('redeemers')[0].userID).toEqual(user1.get('_id'))
                  expect(prepaid.get('redeemers')[0].date).toBeLessThan(new Date())
                  User.findById user1.id, (err, user1) ->
                    expect(err).toBeNull()
                    unsubscribeUser user1, ->
                      User.findById user1.id, (err, user1) ->
                        expect(err).toBeNull()
                        stripeInfo = user1.get('stripe')
                        expect(stripeInfo.prepaidCode).toEqual(prepaid.get('code'))
                        expect(stripeInfo.subscriptionID).toBeDefined()
                        return done() unless stripeInfo.subscriptionID

                        # Delete subscription
                        stripe.customers.retrieveSubscription stripeInfo.customerID, stripeInfo.subscriptionID, (err, subscription) ->
                          expect(err).toBeNull()
                          event = _.cloneDeep(customerSubscriptionDeletedSampleEvent)
                          event.data.object = subscription
                          request.post {uri: webhookURL, json: event}, (err, res, body) ->
                            expect(err).toBeNull()
                            User.findById user1.id, (err, user1) ->
                              expect(err).toBeNull()
                              stripeInfo = user1.get('stripe')
                              expect(stripeInfo.planID).toBeUndefined()
                              expect(stripeInfo.prepaidCode).toBeUndefined()
                              expect(stripeInfo.subscriptionID).toBeUndefined()
                              nockDone()
                              done()

    it 'Subscribe normally, subscribe with valid prepaid', (done) ->
      nockUtils.setupNock 'sub-test-05.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            user1.set('permissions', ['admin'])
            user1.save (err, user1) ->
              expect(err).toBeNull()
              expect(user1.isAdmin()).toEqual(true)
              subscribeUser user1, token, null, ->
                User.findById user1.id, (err, user1) ->
                  expect(err).toBeNull()
                  createPrepaid 'subscription', 1, 0, (err, res, prepaid) ->
                    expect(err).toBeNull()
                    subscribeUser user1, null, prepaid.code, ->
                      Prepaid.findById prepaid._id, (err, prepaid) ->
                        expect(err).toBeNull()
                        expect(prepaid.get('maxRedeemers')).toEqual(1)
                        expect(prepaid.get('redeemers')[0].userID).toEqual(user1.get('_id'))
                        expect(prepaid.get('redeemers')[0].date).toBeLessThan(new Date())
                        User.findById user1.id, (err, user1) ->
                          expect(err).toBeNull()
                          customerID = user1.get('stripe').customerID
                          subscriptionID = user1.get('stripe').subscriptionID
                          stripe.customers.retrieveSubscription customerID, subscriptionID, (err, subscription) ->
                            expect(err).toBeNull()
                            expect(subscription).not.toBeNull()
                            return done() unless subscription
                            expect(subscription.discount?.coupon?.id).toEqual('free')
                            nockDone()
                            done()

    it 'Subscribe with coupon, subscribe with valid prepaid', (done) ->
      nockUtils.setupNock 'sub-test-06.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            user1.set('permissions', ['admin'])
            user1.save (err, user1) ->
              requestBody = user1.toObject()
              requestBody.stripe =
                planID: 'basic'
                token: token.id
                couponID: '20pct'
              request.put {uri: userURL, json: requestBody, headers: headers }, (err, res, updatedUser) ->
                expect(err).toBeNull()
                expect(res.statusCode).toBe(200)
                createPrepaid 'subscription', 1, 0, (err, res, prepaid) ->
                  subscribeUser user1, null, prepaid.code, ->
                    Prepaid.findById prepaid._id, (err, prepaid) ->
                      expect(err).toBeNull()
                      expect(prepaid.get('maxRedeemers')).toEqual(1)
                      expect(prepaid.get('redeemers')[0].userID).toEqual(user1.get('_id'))
                      expect(prepaid.get('redeemers')[0].date).toBeLessThan(new Date())
                      User.findById user1.id, (err, user1) ->
                        expect(err).toBeNull()
                        customerID = user1.get('stripe').customerID
                        subscriptionID = user1.get('stripe').subscriptionID
                        stripe.customers.retrieveSubscription customerID, subscriptionID, (err, subscription) ->
                          expect(err).toBeNull()
                          expect(subscription).not.toBeNull()
                          expect(subscription?.discount?.coupon?.id).toEqual('free')
                          nockDone()
                          done()

    it 'Subscribe with prepaid, then cancel', (done) ->
      nockUtils.setupNock 'sub-test-07.json', (err, nockDone) ->
        loginNewUser (user1) ->
          user1.set('permissions', ['admin'])
          user1.save (err, user1) ->
            expect(err).toBeNull()
            expect(user1.isAdmin()).toEqual(true)
            createPrepaid 'subscription', 1, 0, (err, res, prepaid) ->
              expect(err).toBeNull()
              subscribeUser user1, null, prepaid.code, ->
                Prepaid.findById prepaid._id, (err, prepaid) ->
                  expect(err).toBeNull()
                  expect(prepaid.get('maxRedeemers')).toEqual(1)
                  expect(prepaid.get('redeemers')[0].userID).toEqual(user1.get('_id'))
                  expect(prepaid.get('redeemers')[0].date).toBeLessThan(new Date())
                  User.findById user1.id, (err, user1) ->
                    expect(err).toBeNull()
                    unsubscribeUser user1, ->
                      User.findById user1.id, (err, user1) ->
                        expect(err).toBeNull()
                        expect(user1.get('stripe').prepaidCode).toEqual(prepaid.get('code'))
                        nockDone()
                        done()

    it 'User2 subscribes with used prepaid', (done) ->
      nockUtils.setupNock 'sub-test-08.json', (err, nockDone) ->
        loginNewUser (user1) ->
          user1.set('permissions', ['admin'])
          user1.save (err, user1) ->
            expect(err).toBeNull()
            expect(user1.isAdmin()).toEqual(true)
            createPrepaid 'subscription', 1, 0, (err, res, prepaid) ->
              expect(err).toBeNull()
              subscribeUser user1, null, prepaid.code, ->
                loginNewUser (user2) ->
                  requestBody = user2.toObject()
                  requestBody.stripe =
                    planID: 'basic'
                  requestBody.stripe.prepaidCode = prepaid.code
                  request.put {uri: userURL, json: requestBody, headers: headers }, (err, res, body) ->
                    expect(err).toBeNull()
                    expect(res.statusCode).toBe(403)
                    Prepaid.findById prepaid._id, (err, prepaid) ->
                      expect(err).toBeNull()
                      expect(prepaid.get('redeemers')[0].userID).toEqual(user1.get('_id'))
                      expect(prepaid.get('redeemers')[0].date).toBeLessThan(new Date())
                      nockDone()
                      done()

    it 'User2 subscribes with same active prepaid', (done) ->
      nockUtils.setupNock 'sub-test-09.json', (err, nockDone) ->
        loginNewUser (user1) ->
          user1.set('permissions', ['admin'])
          user1.save (err, user1) ->
            expect(err).toBeNull()
            expect(user1.isAdmin()).toEqual(true)
            createPrepaid 'subscription', 2, 0, (err, res, prepaid) ->
              expect(err).toBeNull()
              subscribeUser user1, null, prepaid.code, ->
                loginNewUser (user2) ->
                  subscribeUser user2, null, prepaid.code, ->
                    Prepaid.findById prepaid._id, (err, prepaid) ->
                      expect(err).toBeNull()
                      expect(prepaid.get('redeemers').length).toEqual(2)
                      nockDone()
                      done()

    it 'Admin subscribes self with valid prepaid', (done) ->
      nockUtils.setupNock 'sub-test-10.json', (err, nockDone) ->
        loginNewUser (user1) ->
          user1.set('permissions', ['admin'])
          user1.save (err, user1) ->
            expect(err).toBeNull()
            expect(user1.isAdmin()).toEqual(true)
            createPrepaid 'subscription', 1, 0, (err, res, prepaid) ->
              expect(err).toBeNull()
              subscribeUser user1, null, prepaid.code, ->
                Prepaid.findById prepaid._id, (err, prepaid) ->
                  expect(err).toBeNull()
                  expect(prepaid.get('maxRedeemers')).toEqual(1)
                  expect(prepaid.get('redeemers')[0].userID).toEqual(user1.get('_id'))
                  expect(prepaid.get('redeemers')[0].date).toBeLessThan(new Date())
                  nockDone()
                  done()

    it 'Admin subscribes self with valid prepaid twice', (done) ->
      nockUtils.setupNock 'sub-test-11.json', (err, nockDone) ->
        loginNewUser (user1) ->
          user1.set('permissions', ['admin'])
          user1.save (err, user1) ->
            expect(err).toBeNull()
            expect(user1.isAdmin()).toEqual(true)
            createPrepaid 'subscription', 2, 0, (err, res, prepaid) ->
              expect(err).toBeNull()
              Prepaid.findById prepaid._id, (err, prepaid) ->
                expect(err).toBeNull()
                prepaid.set 'redeemers', [{userID: user1.get('_id'), date: new Date()}]
                prepaid.save (err) ->
                  expect(err).toBeNull()
                  requestBody = user1.toObject()
                  requestBody.stripe =
                    planID: 'basic'
                  requestBody.stripe.prepaidCode = prepaid.get('code')
                  request.put {uri: userURL, json: requestBody, headers: headers }, (err, res, body) ->
                    expect(err).toBeNull()
                    expect(res.statusCode).toBe(403)
                    nockDone()
                    done()

    it 'Admin subscribes self with invalid prepaid', (done) ->
      nockUtils.setupNock 'sub-test-12.json', (err, nockDone) ->
        loginNewUser (user1) ->
          user1.set('permissions', ['admin'])
          user1.save (err, user1) ->
            expect(err).toBeNull()
            expect(user1.isAdmin()).toEqual(true)
            requestBody = user1.toObject()
            requestBody.stripe =
              planID: 'basic'
            requestBody.stripe.prepaidCode = 'MattMatt'
            request.put {uri: userURL, json: requestBody, headers: headers }, (err, res, body) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(404)
              nockDone()
              done()

    it 'returns 403 when trying to subscribe with stripe over an existing PayPal subscription', utils.wrap ->
      user = yield utils.initUser()
      yield utils.loginUser(user)
      user.set('payPal.billingAgreementID', 'foo')
      yield user.save()
      requestBody = user.toObject()
      requestBody.stripe =
        planID: 'basic'
        token: {id: 'bar'}
      [res, body] = yield request.putAsync({uri: userURL, json: requestBody, headers: headers })
      expect(res.statusCode).toBe(403)

  describe 'APIs', ->
    # TODO: Refactor these tests to be use yield, be independent of one another, and move to products.spec.coffee
    # TODO: year tests converted to lifetime, but should be reviewed for usefulness
    subscriptionURL = getURL('/db/subscription')
    purchaseLifetimeUrl = null
    beforeEach utils.wrap (done) ->
      yield utils.populateProducts()
      @product = yield Product.findOne({name: 'lifetime_subscription'})
      purchaseLifetimeUrl = getURL("/db/products/#{@product.id}/purchase")
      done()

    it 'lifetime sub', (done) ->
      product = @product
      nockUtils.setupNock 'sub-test-35.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            expect(user1.get('stripe')?.free).toBeUndefined()
            requestBody =
              stripe:
                token: token.id
                timestamp: new Date()
            request.post {uri: purchaseLifetimeUrl, json: requestBody, headers: headers }, (err, res) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(200)
              User.findById user1.id, (err, user1) ->
                expect(err).toBeNull()
                stripeInfo = user1.get('stripe')
                expect(stripeInfo).toBeDefined()
                return done() unless stripeInfo
                expect(stripeInfo.free).toEqual(true)
                expect(stripeInfo.customerID).toBeDefined()
                expect(user1.get('purchased')?.gems).toEqual(subGems*12)
                Payment.findOne 'stripe.customerID': stripeInfo.customerID, (err, payment) ->
                  expect(err).toBeNull()
                  expect(payment).toBeTruthy()
                  expect(payment.get('gems')).toEqual(subGems*12)
                  expect(payment.get('productID')).toBe(product.get('name'))
                  nockDone()
                  done()

    # TODO: Is the behavior being tested here correct? Seems like one shouldn't be able (or need) to buy a lifetime sub when stripe.free is already true.
    it 'lifetime sub when stripe.free === true', (done) ->
      nockUtils.setupNock 'sub-test-36.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            user1.set('stripe', {free: true})
            user1.save (err, user1) ->
              expect(err).toBeNull()
              expect(user1.get('stripe')?.free).toEqual(true)
              requestBody =
                stripe:
                  token: token.id
                  timestamp: new Date()
              request.post {uri: purchaseLifetimeUrl, json: requestBody, headers: headers }, (err, res) ->
                expect(err).toBeNull()
                expect(res.statusCode).toBe(200)
                User.findById user1.id, (err, user1) ->
                  expect(err).toBeNull()
                  stripeInfo = user1.get('stripe')
                  expect(stripeInfo).toBeDefined()
                  return done() unless stripeInfo
                  expect(stripeInfo.free).toEqual(true)
                  expect(stripeInfo.customerID).toBeDefined()
                  expect(user1.get('purchased')?.gems).toEqual(subGems*12)
                  Payment.findOne 'stripe.customerID': stripeInfo.customerID, (err, payment) ->
                    expect(err).toBeNull()
                    expect(payment).toBeTruthy()
                    expect(payment.get('gems')).toEqual(subGems*12)
                    nockDone()
                    done()

    it 'lifetime sub when stripe.free < today', (done) ->
      nockUtils.setupNock 'sub-test-37.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            endDate = new Date()
            endDate.setUTCFullYear(endDate.getUTCFullYear() - 1)
            user1.set('stripe', {free: endDate.toISOString().substring(0, 10)})
            user1.save (err, user1) ->
              expect(err).toBeNull()
              expect(user1.get('stripe')?.free).toEqual(endDate.toISOString().substring(0, 10))
              requestBody =
                stripe:
                  token: token.id
                  timestamp: new Date()
              request.post {uri: purchaseLifetimeUrl, json: requestBody, headers: headers }, (err, res) ->
                expect(err).toBeNull()
                expect(res.statusCode).toBe(200)
                User.findById user1.id, (err, user1) ->
                  expect(err).toBeNull()
                  stripeInfo = user1.get('stripe')
                  expect(stripeInfo).toBeDefined()
                  return done() unless stripeInfo
                  expect(stripeInfo.free).toEqual(true)
                  expect(stripeInfo.customerID).toBeDefined()
                  expect(user1.get('purchased')?.gems).toEqual(subGems*12)
                  Payment.findOne 'stripe.customerID': stripeInfo.customerID, (err, payment) ->
                    expect(err).toBeNull()
                    expect(payment).toBeTruthy()
                    expect(payment.get('gems')).toEqual(subGems*12)
                    nockDone()
                    done()

    it 'lifetime sub when stripe.free > today', (done) ->
      nockUtils.setupNock 'sub-test-38.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            endDate = new Date()
            endDate.setUTCDate(endDate.getUTCDate() + 5)
            user1.set('stripe', {free: endDate.toISOString().substring(0, 10)})
            user1.save (err, user1) ->
              expect(err).toBeNull()
              expect(user1.get('stripe')?.free).toEqual(endDate.toISOString().substring(0, 10))
              requestBody =
                stripe:
                  token: token.id
                  timestamp: new Date()
              request.post {uri: purchaseLifetimeUrl, json: requestBody, headers: headers }, (err, res) ->
                expect(err).toBeNull()
                expect(res.statusCode).toBe(200)
                User.findById user1.id, (err, user1) ->
                  expect(err).toBeNull()
                  stripeInfo = user1.get('stripe')
                  expect(stripeInfo).toBeDefined()
                  return done() unless stripeInfo
                  expect(stripeInfo.free).toEqual(true)
                  expect(stripeInfo.customerID).toBeDefined()
                  expect(user1.get('purchased')?.gems).toEqual(subGems*12)
                  Payment.findOne 'stripe.customerID': stripeInfo.customerID, (err, payment) ->
                    expect(err).toBeNull()
                    expect(payment).toBeTruthy()
                    expect(payment.get('gems')).toEqual(subGems*12)
                    nockDone()
                    done()

    it 'lifetime sub with monthly sub', (done) ->
      nockUtils.setupNock 'sub-test-39.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            subscribeUser user1, token, null, ->
              User.findById user1.id, (err, user1) ->
                expect(err).toBeNull()
                stripeInfo = user1.get('stripe')
                stripe.customers.retrieveSubscription stripeInfo.customerID, stripeInfo.subscriptionID, (err, subscription) ->
                  expect(err).toBeNull()
                  expect(subscription).not.toBeNull()
                  stripeSubscriptionPeriodEndDate = new Date(subscription.current_period_end * 1000)
                  stripe.tokens.create {
                    card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
                  }, (err, token) ->
                    requestBody =
                      stripe:
                        token: token.id
                        timestamp: new Date()
                    request.post {uri: purchaseLifetimeUrl, json: requestBody, headers: headers }, (err, res) ->
                      expect(err).toBeNull()
                      expect(res.statusCode).toBe(200)
                      User.findById user1.id, (err, user1) ->
                        expect(err).toBeNull()
                        stripeInfo = user1.get('stripe')
                        expect(stripeInfo).toBeDefined()
                        return done() unless stripeInfo
                        expect(stripeInfo.free).toEqual(true)
                        expect(stripeInfo.customerID).toBeDefined()
                        expect(user1.get('purchased')?.gems).toEqual(subGems+subGems*12)
                        Payment.findOne 'stripe.customerID': stripeInfo.customerID, (err, payment) ->
                          expect(err).toBeNull()
                          expect(payment).toBeTruthy()
                          expect(payment.get('gems')).toEqual(subGems*12)
                          nockDone()
                          done()

  describe 'Countries', ->
    it 'Brazil users get Brazil coupon', (done) ->
      nockUtils.setupNock 'sub-test-41.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2030, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            user1.set('country', 'brazil')
            user1.save (err, user1) ->
              requestBody = user1.toObject()
              requestBody.stripe =
                planID: 'basic'
                token: token.id
              request.put {uri: userURL, json: requestBody, headers: headers }, (err, res, updatedUser) ->
                expect(err).toBeNull()
                expect(res.statusCode).toBe(200)
                expect(updatedUser.country).toBe('brazil')
                expect(updatedUser.purchased.gems).toBe(subGemsBrazil)
                expect(updatedUser.stripe.planID).toBe('basic')
                expect(updatedUser.stripe.customerID).toBeTruthy()

                stripe.invoices.list {customer: updatedUser.stripe.customerID}, (err, invoices) ->
                  expect(err).toBeNull()
                  expect(invoices).not.toBeNull()
                  expect(invoices.data.length).toBe(1)
                  expect(invoices.data[0].discount?.coupon).toBeTruthy()
                  expect(invoices.data[0].discount?.coupon?.id).toBe('brazil')
                  expect(invoices.data[0].total).toBeLessThan(subPrice)

                  # Now we hit our webhook to see if the right Payment is made.
                  event = _.cloneDeep(invoiceChargeSampleEvent)
                  event.data.object = invoices.data[0]
                  request.post {uri: webhookURL, json: event}, (err, res, body) ->
                    expect(err).toBeNull()
                    expect(res.statusCode).toBe(201)
                    Payment.findOne 'stripe.customerID': updatedUser.stripe.customerID, (err, payment) ->
                      expect(err).toBeNull()
                      expect(payment).toBeTruthy()
                      return done() unless payment
                      expect(payment.get('gems')).toEqual(subGemsBrazil)
                      expect(payment.get('amount')).toBeLessThan(subPrice)
                      nockDone()
                      done()


describe 'DELETE /db/user/:handle/stripe/recipients/:recipientHandle', ->

  beforeEach utils.wrap ->
    yield utils.clearModels([User])

    @recipient1 = yield utils.initUser()
    @recipient2 = yield utils.initUser()
    @sponsor = yield utils.initUser({
      stripe: {
        customerID: 'a'
        sponsorSubscriptionID: '1'
        recipients: [
          {
            userID: @recipient1.id
            subscriptionID: '2'
            couponID: 'free'
          }
          {
            userID: @recipient2.id
            subscriptionID: '3'
            couponID: 'free'
          }
        ]
      }
    })
    yield @recipient1.update({$set: {stripe: {sponsorID: @sponsor.id}}})
    yield @recipient2.update({$set: {stripe: {sponsorID: @sponsor.id}}})
    yield utils.populateProducts()
    spyOn(stripe.customers, 'cancelSubscription').and.callFake (cId, sId, cb) -> cb(null)
    spyOn(stripe.customers, 'updateSubscription').and.callFake (cId, sId, opts, cb) -> cb(null)

  it 'unsubscribes the given recipient', utils.wrap ->
    yield utils.loginUser(@sponsor)
    url = utils.getURL("/db/user/#{@sponsor.id}/stripe/recipients/#{@recipient1.id}")
    [res, body] = yield request.delAsync({url, json:true})
    expect(res.statusCode).toBe(200)
    expect(res.body.stripe.recipients.length).toBe(1)
    expect(res.body.stripe.recipients[0].userID).toBe(@recipient2.id)
    expect((yield User.findById(@sponsor.id)).get('stripe').recipients.length).toBe(1)
    expect((yield User.findById(@recipient1.id)).get('stripe')).toBeUndefined()
    expect((yield User.findById(@recipient2.id)).get('stripe')).toBeDefined()


describe 'POST /db/products/:handle/purchase', ->
  describe 'when logged in user', ->
    beforeEach utils.wrap ->
      @user = yield utils.initUser()
      yield utils.loginUser(@user)
      yield utils.populateProducts()

    describe 'when subscribed', ->
      beforeEach utils.wrap ->
        @billingAgreementID = 1234
        @user.set('payPal.billingAgreementID', @billingAgreementID)
        yield @user.save()

      it 'denies PayPal payments', utils.wrap ->
        product = yield Product.findOne({ name: 'lifetime_subscription' })
        url = utils.getUrl("/db/products/#{product.id}/purchase")
        json = { service: 'paypal', paymentID: "PAY-74521676DM528663SLFT63RA", payerID: 'VUR529XNB59XY' }
        [res] = yield request.postAsync({ url, json })
        expect(res.statusCode).toBe(403)

    describe 'when NOT subscribed', ->
      it 'accepts PayPal payments', utils.wrap ->
        # TODO: figure out how to create test payments through PayPal API, set this up with fixtures through Nock

        product = yield Product.findOne({ name: 'lifetime_subscription' })
        amount = product.get('amount')
        url = utils.getUrl("/db/products/#{product.id}/purchase")
        json = { service: 'paypal', paymentID: "PAY-74521676DM528663SLFT63RA", payerID: 'VUR529XNB59XY' }

        payPalResponse = {
          "id": "PAY-03466",
          "intent": "sale",
          "state": "approved",
          "cart": "3J885",
          "payer": {
            "payment_method": "paypal",
            "status": "VERIFIED",
            "payer_info": {
              "email": @user.get('email'),
              "first_name": "test",
              "last_name": "buyer",
              "payer_id": "VUR529XNB59XY",
              "shipping_address": {
                "recipient_name": "test buyer",
                "line1": "1 Main St",
                "city": "San Jose",
                "state": "CA",
                "postal_code": "95131",
                "country_code": "US"
              },
              "country_code": "US"
            }
          },
          "transactions": [
            {
              "amount": {
                "total": (amount/100).toFixed(2),
                "currency": "USD",
                "details": {}
              },
              "payee": {
                "merchant_id": "7R5CJJ",
                "email": "payments@codecombat.com"
              },
              "description": "Lifetime Subscription",
              "item_list": {
                "items": [
                  {
                    "name": "lifetime_subscription",
                    "sku": product.id,
                    "price": (amount/100).toFixed(2),
                    "currency": "USD",
                    "quantity": 1
                  }
                ],
                "shipping_address": {
                  "recipient_name": "test buyer",
                  "line1": "1 Main St",
                  "city": "San Jose",
                  "state": "CA",
                  "postal_code": "95131",
                  "country_code": "US"
                }
              },
              "related_resources": [] # bunch more info in here
            }
          ],
          "create_time": "2017-07-13T22:35:45Z",
          "links": [
            {
              "href": "https://api.sandbox.paypal.com/v1/payments/payment/PAY-034662230Y592723RLFT7LLA",
              "rel": "self",
              "method": "GET"
            }
          ],
          "httpStatusCode": 200
        }
        spyOn(paypal.payment, 'executeAsync').and.returnValue(Promise.resolve(payPalResponse))

        [res] = yield request.postAsync({ url, json })
        expect(res.statusCode).toBe(200)
        payment = yield Payment.findOne({"payPal.id":"PAY-03466"})
        expect(payment).toBeDefined()
        expect(payment.get('productID')).toBe(product.get('name'))
        expect(payment.get('payPal.id')).toBe(payPalResponse.id)
        expect(payment.get('amount')).toBe(product.get('amount'))
        user = yield User.findById(@user.id)
        expect(user.get('stripe.free')).toBe(true)
        expect(user.get('payPal').payerID).toEqual(payPalResponse.payer.payer_info.payer_id)
        expect(user.hasSubscription()).toBeTruthy()

      it 'accepts PayPal payments with coupon', utils.wrap ->
        # TODO: figure out how to create test payments through PayPal API, set this up with fixtures through Nock

        product = yield Product.findOne({ name: 'lifetime_subscription' })
        amount = product.get('coupons')[0].amount
        url = utils.getUrl("/db/products/#{product.id}/purchase")
        json = { service: 'paypal', paymentID: "PAY-74521676DM528663SLFT63RA", payerID: 'VUR529XNB59XY', coupon: 'c1' }

        payPalResponse = {
          "id": "PAY-84848",
          "intent": "sale",
          "state": "approved",
          "cart": "3J885",
          "payer": {
            "payment_method": "paypal",
            "status": "VERIFIED",
            "payer_info": {
              "email": @user.get('email'),
              "first_name": "test",
              "last_name": "buyer",
              "payer_id": "VUR529XNB59XY",
              "shipping_address": {
                "recipient_name": "test buyer",
                "line1": "1 Main St",
                "city": "San Jose",
                "state": "CA",
                "postal_code": "95131",
                "country_code": "US"
              },
              "country_code": "US"
            }
          },
          "transactions": [
            {
              "amount": {
                "total": (amount/100).toFixed(2),
                "currency": "USD",
                "details": {}
              },
              "payee": {
                "merchant_id": "7R5CJJ",
                "email": "payments@codecombat.com"
              },
              "description": "Lifetime Subscription",
              "item_list": {
                "items": [
                  {
                    "name": "lifetime_subscription",
                    "sku": product.id,
                    "price": (amount/100).toFixed(2),
                    "currency": "USD",
                    "quantity": 1
                  }
                ],
                "shipping_address": {
                  "recipient_name": "test buyer",
                  "line1": "1 Main St",
                  "city": "San Jose",
                  "state": "CA",
                  "postal_code": "95131",
                  "country_code": "US"
                }
              },
              "related_resources": [] # bunch more info in here
            }
          ],
          "create_time": "2017-07-13T22:35:45Z",
          "links": [
            {
              "href": "https://api.sandbox.paypal.com/v1/payments/payment/PAY-034662230Y592723RLFT7LLA",
              "rel": "self",
              "method": "GET"
            }
          ],
          "httpStatusCode": 200
        }
        spyOn(paypal.payment, 'executeAsync').and.returnValue(Promise.resolve(payPalResponse))

        [res] = yield request.postAsync({ url, json })
        expect(res.statusCode).toBe(200)
        payment = yield Payment.findOne({"payPal.id":"PAY-84848"})
        expect(payment).toBeDefined()
        expect(payment.get('productID')).toBe(product.get('name'))
        expect(payment.get('payPal.id')).toBe(payPalResponse.id)
        expect(payment.get('amount')).toBe(product.get('coupons')[0].amount)
        user = yield User.findById(@user.id)
        expect(user.get('stripe.free')).toBe(true)
        expect(user.get('payPal').payerID).toEqual(payPalResponse.payer.payer_info.payer_id)
        expect(user.hasSubscription()).toBeTruthy()

describe 'POST /db/user/:handle/paypal', ->
  describe '/create-billing-agreement', ->
    beforeEach utils.wrap ->
      @payPalResponse = {
        "name":"[TEST agreement] CodeCombat Premium Subscription",
        "description":"[TEST agreeement] A CodeCombat Premium subscription gives you access to exclusive levels, heroes, equipment, pets and more!",
        "plan":{
            "id": "TODO",
            "state":"ACTIVE",
            "name":"[TEST plan] CodeCombat Premium Subscription",
            "description":"[TEST plan] A CodeCombat Premium subscription gives you access to exclusive levels, heroes, equipment, pets and more!",
            "type":"INFINITE",
            "payment_definitions":[
              {
                  "id":"PD-2M295453FC097664LX2K4IKA",
                  "name":"Regular payment definition",
                  "type":"REGULAR",
                  "frequency":"Day",
                  "amount":{
                    "currency":"USD",
                    "value": "TODO"
                  },
                  "cycles":"0",
                  "charge_models":[

                  ],
                  "frequency_interval":"1"
              }
            ],
            "merchant_preferences":{
              "setup_fee":{
                  "currency":"USD",
                  "value":"0"
              },
              "max_fail_attempts":"0",
              "return_url":"http://localhost:3000/paypal/subscribe-callback",
              "cancel_url":"http://localhost:3000/paypal/cancel-callback",
              "auto_bill_amount":"YES",
              "initial_fail_amount_action":"CONTINUE"
            }
        },
        "links":[
            {
              "href":"https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token=EC-92B61638JR311510D",
              "rel":"approval_url",
              "method":"REDIRECT"
            },
            {
              "href":"https://api.sandbox.paypal.com/v1/payments/billing-agreements/EC-92B61638JR311510D/agreement-execute",
              "rel":"execute",
              "method":"POST"
            }
        ],
        "start_date":"2017-08-08T18:47:06.681Z",
        "httpStatusCode":201
      }

    describe 'when user NOT logged in', ->
      beforeEach utils.wrap ->
        @user = yield utils.becomeAnonymous()
        yield utils.populateProducts()
        @product = yield Product.findOne({ name: 'basic_subscription' })

      it 'returns 401 and does not create a billing agreement', utils.wrap ->
        url = utils.getUrl("/db/user/#{@user.id}/paypal/create-billing-agreement")
        [res, body] = yield request.postAsync({ url, json: {productID: @product.id} })

        expect(res.statusCode).toBe(401)
        expect(@user.isAnonymous()).toBeTruthy()

    describe 'when user logged in', ->
      beforeEach utils.wrap ->
        @user = yield utils.initUser()
        yield utils.loginUser(@user)

      describe 'when user already subscribed', ->
        beforeEach utils.wrap ->
          @user.set('payPal.billingAgreementID', 'foo')
          yield @user.save()
          @product = yield Product.findOne({ name: 'brazil_basic_subscription' })

        it 'returns 403 and does not create a billing agreement', utils.wrap ->
          url = utils.getUrl("/db/user/#{@user.id}/paypal/create-billing-agreement")
          [res, body] = yield request.postAsync({ url, json: {productID: @product.id} })
          expect(res.statusCode).toBe(403)
          expect(@user.get('payPal.billingAgreementID')).toEqual('foo')

      describe 'when invalid product', ->

        it 'returns 422 and does not create a billing agreement', utils.wrap ->
          url = utils.getUrl("/db/user/#{@user.id}/paypal/create-billing-agreement")
          [res, body] = yield request.postAsync({ url, json: {productID: 99999} })

          expect(res.statusCode).toBe(422)

      describe 'when regional product', ->
        beforeEach utils.wrap ->
          yield utils.populateProducts()
          @product = yield Product.findOne({ name: 'brazil_basic_subscription' })
          @payPalResponse.plan.id = @product.get('payPalBillingPlanID')
          @payPalResponse.plan.payment_definitions[0].amount.value = parseFloat(@product.get('amount') / 100).toFixed(2)

        it 'creates a billing agreement', utils.wrap ->
          url = utils.getUrl("/db/user/#{@user.id}/paypal/create-billing-agreement")
          spyOn(paypal.billingAgreement, 'createAsync').and.returnValue(Promise.resolve(@payPalResponse))
          [res, body] = yield request.postAsync({ url, json: {productID: @product.id} })
          expect(res.statusCode).toBe(201)
          expect(body.plan.id).toEqual(@product.get('payPalBillingPlanID'))
          expect(body.plan.payment_definitions[0].amount.value).toEqual(parseFloat(@product.get('amount') / 100).toFixed(2))

      describe 'when basic product', ->
        beforeEach utils.wrap ->
          yield utils.populateProducts()
          @product = yield Product.findOne({ name: 'basic_subscription' })
          @payPalResponse.plan.id = @product.get('payPalBillingPlanID')
          @payPalResponse.plan.payment_definitions[0].amount.value = parseFloat(@product.get('amount') / 100).toFixed(2)

        it 'creates a billing agreement', utils.wrap ->
          url = utils.getUrl("/db/user/#{@user.id}/paypal/create-billing-agreement")
          spyOn(paypal.billingAgreement, 'createAsync').and.returnValue(Promise.resolve(@payPalResponse))
          [res, body] = yield request.postAsync({ url, json: {productID: @product.id} })
          expect(res.statusCode).toBe(201)
          expect(body.plan.id).toEqual(@product.get('payPalBillingPlanID'))
          expect(body.plan.payment_definitions[0].amount.value).toEqual(parseFloat(@product.get('amount') / 100).toFixed(2))

  describe '/execute-billing-agreement', ->
    beforeEach utils.wrap ->
      @payPalResponse = {
        "id": "I-3HNGD4BKF09P",
        "state": "Active",
        "description": "[TEST agreeement] A CodeCombat Premium subscription gives you access to exclusive levels, heroes, equipment, pets and more!",
        "payer": {
          "payment_method": "paypal",
          "status": "verified",
          "payer_info": {
            "email": "foo@bar.com",
            "first_name": "Foo",
            "last_name": "Bar",
            "payer_id": "1324",
          }
        },
        "plan": {
          "payment_definitions": [
            {
              "type": "REGULAR",
              "frequency": "Day",
              "amount": {
                "value": "TODO"
              },
              "cycles": "0",
              "charge_models": [
                {
                  "type": "TAX",
                  "amount": {
                    "value": "0.00"
                  }
                },
                {
                  "type": "SHIPPING",
                  "amount": {
                    "value": "0.00"
                  }
                }
              ],
              "frequency_interval": "1"
            }
          ],
          "merchant_preferences": {
            "setup_fee": {
              "value": "0.00"
            },
            "max_fail_attempts": "0",
            "auto_bill_amount": "YES"
          },
          "links": [],
          "currency_code": "USD"
        },
        "links": [
          {
            "href": "https://api.sandbox.paypal.com/v1/payments/billing-agreements/I-3HNGD4BKF09P",
            "rel": "self",
            "method": "GET"
          }
        ],
        "start_date": "2017-08-08T07:00:00Z",
        "agreement_details": {
          "outstanding_balance": {
            "value": "0.00"
          },
          "cycles_remaining": "0",
          "cycles_completed": "0",
          "next_billing_date": "2017-08-08T10:00:00Z",
          "final_payment_date": "1970-01-01T00:00:00Z",
          "failed_payment_count": "0"
        },
        "httpStatusCode": 200
      }

    describe 'when user NOT logged in', ->
      beforeEach utils.wrap ->
        @user = yield utils.becomeAnonymous()
        yield utils.populateProducts()

      it 'returns 401 and does not execute a billing agreement', utils.wrap ->
        url = utils.getUrl("/db/user/#{@user.id}/paypal/execute-billing-agreement")
        [res, body] = yield request.postAsync({ url })
        expect(res.statusCode).toBe(401)
        expect(@user.isAnonymous()).toBeTruthy()

    describe 'when user logged in', ->
      beforeEach utils.wrap ->
        @user = yield utils.initUser()
        yield utils.loginUser(@user)

      describe 'when user already subscribed', ->
        beforeEach utils.wrap ->
          @user.set('payPal.billingAgreementID', 'foo')
          yield @user.save()

        it 'returns 403 and does not execute a billing agreement', utils.wrap ->
          url = utils.getUrl("/db/user/#{@user.id}/paypal/execute-billing-agreement")
          [res, body] = yield request.postAsync({ url })
          expect(res.statusCode).toBe(403)
          expect(@user.get('payPal.billingAgreementID')).toEqual('foo')

      describe 'when no token', ->

        it 'returns 404 and does not execute a billing agreement', utils.wrap ->
          url = utils.getUrl("/db/user/#{@user.id}/paypal/execute-billing-agreement")
          [res, body] = yield request.postAsync({ url })
          expect(res.statusCode).toBe(404)

      describe 'when token passed', ->
        beforeEach utils.wrap ->
          @product = yield Product.findOne({name: 'basic_subscription'})
          unless @product
            @localProduct = true
            @product = Product({name: 'basic_subscription', gems: 20, amount: 30})
            yield @product.save()
          # else
          #   console.log '@product exists', @product
        afterEach utils.wrap ->
          if @localProduct
            yield Product.remove({_id: @product.get('_id')})
        it 'subscribes the user', utils.wrap ->
          expect(@user.hasSubscription()).not.toBeTruthy()
          url = utils.getUrl("/db/user/#{@user.id}/paypal/execute-billing-agreement")
          spyOn(paypal.billingAgreement, 'executeAsync').and.returnValue(Promise.resolve(@payPalResponse))
          [res, body] = yield request.postAsync({ url, json: {token: 'foo' }})
          expect(res.statusCode).toBe(200)
          expect(body.id).toEqual(@payPalResponse.id)
          user = yield User.findById @user.id
          userPayPalData = user.get('payPal')
          expect(userPayPalData.billingAgreementID).toEqual(@payPalResponse.id)
          expect(userPayPalData.payerID).toEqual(@payPalResponse.payer.payer_info.payer_id)
          expect(userPayPalData.subscribeDate).toBeDefined()
          expect(userPayPalData.subscribeDate).toBeLessThan(new Date())
          expect(user.hasSubscription()).toBeTruthy()
          payment = yield Payment.findOne payPalBillingAgreementID: userPayPalData.billingAgreementID
          expect(payment).toBeDefined()
          expect(payment.get('recipient').toString()).toEqual(user.id)
          expect(payment.get('amount')).toEqual(@product.get('amount'))
          expect(payment.get('gems')).toEqual(@product.get('gems'))
          expect(user.get('purchased').gems).toEqual(@product.get('gems'))

  describe '/cancel-billing-agreement', ->
    beforeEach utils.wrap ->
      @payPalResponse = {
        "httpStatusCode": 204
      }

    describe 'when user NOT logged in', ->
      beforeEach utils.wrap ->
        @user = yield utils.becomeAnonymous()
        yield utils.populateProducts()

      it 'no billing agreement cancelled', utils.wrap ->
        url = utils.getUrl("/db/user/#{@user.id}/paypal/cancel-billing-agreement")
        [res, body] = yield request.postAsync({ url })
        expect(res.statusCode).toBe(401)
        expect(@user.isAnonymous()).toBeTruthy()

    describe 'when user logged in', ->
      beforeEach utils.wrap ->
        @user = yield utils.initUser()
        yield utils.loginUser(@user)

      describe 'when user not subscribed', ->

        it 'no billing agreement cancelled', utils.wrap ->
          url = utils.getUrl("/db/user/#{@user.id}/paypal/cancel-billing-agreement")
          [res, body] = yield request.postAsync({ url })
          expect(res.statusCode).toBe(403)

      describe 'when user subscribed', ->
        beforeEach utils.wrap ->
          @billingAgreementID = 1234
          @user.set('payPal.billingAgreementID', @billingAgreementID)
          yield @user.save()

        it 'user unsubscribed', utils.wrap ->
          expect(@user.hasSubscription()).toBeTruthy()
          url = utils.getUrl("/db/user/#{@user.id}/paypal/cancel-billing-agreement")
          spyOn(paypal.billingAgreement, 'cancelAsync').and.returnValue(Promise.resolve(@payPalResponse))
          [res, body] = yield request.postAsync({ url, json: {billingAgreementID: @billingAgreementID} })
          expect(res.statusCode).toBe(204)
          user = yield User.findById @user.id
          expect(user.get('payPal').billingAgreementID).not.toBeDefined()
          expect(user.get('payPal').cancelDate).toBeDefined()
          expect(user.get('payPal').cancelDate).toBeLessThan(new Date())
          expect(user.hasSubscription()).toBeTruthy()
          expect(new Date(user.get('stripe').free)).toBeGreaterThan(new Date())

describe 'POST /paypal/webhook', ->
  beforeEach utils.wrap ->
    yield utils.clearModels([User, Payment])

  describe 'when unknown event', ->

    it 'returns 200 and info message', utils.wrap ->
      url = getURL('/paypal/webhook')
      [res, body] = yield request.postAsync({ uri: url, json: {event_type: "UNKNOWN.EVENT"} })
      expect(res.statusCode).toEqual(200)
      expect(res.body).toEqual('PayPal webhook unknown event UNKNOWN.EVENT')

  describe 'when PAYMENT.SALE.COMPLETED event', ->

    describe 'when billing agreement payment', ->
      beforeEach utils.wrap ->
        @paymentEventData = {
          "id":"WH-7UE28022AT424841V-9DJ65866TC5772327",
          "event_version":"1.0",
          "create_time":"2017-08-07T23:33:37.176Z",
          "resource_type":"sale",
          "event_type":"PAYMENT.SALE.COMPLETED",
          "summary":"Payment completed for $ 0.99 USD",
          "resource":{
              "id":"3C172741YC758734U",
              "state":"completed",
              "amount":{
                "total":"0.99",
                "currency":"USD",
                "details":{

                }
              },
              "payment_mode":"INSTANT_TRANSFER",
              "protection_eligibility":"ELIGIBLE",
              "protection_eligibility_type":"ITEM_NOT_RECEIVED_ELIGIBLE,UNAUTHORIZED_PAYMENT_ELIGIBLE",
              "transaction_fee":{
                "value":"0.02",
                "currency":"USD"
              },
              "billing_agreement_id":"I-H3HN1PXG1SEV",
              "create_time":"2017-08-07T23:33:10Z",
              "update_time":"2017-08-07T23:33:10Z",
              "links":[
                {
                    "href":"https://api.sandbox.paypal.com/v1/payments/sale/3C172741YC758734U",
                    "rel":"self",
                    "method":"GET"
                },
                {
                    "href":"https://api.sandbox.paypal.com/v1/payments/sale/3C172741YC758734U/refund",
                    "rel":"refund",
                    "method":"POST"
                }
              ]
          },
          "links":[
              {
                "href":"https://api.sandbox.paypal.com/v1/notifications/webhooks-events/WH-7UE28022AT424841V-9DJ65866TC5772327",
                "rel":"self",
                "method":"GET"
              },
              {
                "href":"https://api.sandbox.paypal.com/v1/notifications/webhooks-events/WH-7UE28022AT424841V-9DJ65866TC5772327/resend",
                "rel":"resend",
                "method":"POST"
              }
          ]
        }

      describe 'when incomplete', ->

        it 'returns 200 and incomplete message', utils.wrap ->
          @paymentEventData.resource.state = 'incomplete'
          url = getURL('/paypal/webhook')
          [res, body] = yield request.postAsync({ uri: url, json: @paymentEventData })
          expect(res.statusCode).toEqual(200)
          expect(res.body).toEqual("PayPal webhook payment incomplete state: #{@paymentEventData.resource.id} #{@paymentEventData.resource.state}")

      describe 'when no user with billing agreement', ->

        it 'returns 200 and no user message', utils.wrap ->
          url = getURL('/paypal/webhook')
          [res, body] = yield request.postAsync({ uri: url, json: @paymentEventData })
          expect(res.statusCode).toEqual(200)
          expect(res.body).toEqual("PayPal webhook payment no user found: #{@paymentEventData.resource.id} #{@paymentEventData.resource.billing_agreement_id}")

      describe 'when user with billing agreement', ->
        beforeEach utils.wrap ->
          @user = yield utils.initUser()
          yield utils.loginUser(@user)
          @user.set('payPal.billingAgreementID', @paymentEventData.resource.billing_agreement_id)
          yield @user.save()

        xdescribe 'when no basic_subscription product for user', ->
          beforeEach utils.wrap ->
            # TODO: populateProducts runs once, so this could mess with following tests.
            yield utils.clearModels([Product])

          it 'returns 200 and unexpected sub message', utils.wrap ->
            url = getURL('/paypal/webhook')
            [res, body] = yield request.postAsync({ uri: url, json: @paymentEventData })
            expect(res.statusCode).toEqual(200)
            expect(res.body).toEqual("PayPal webhook unexpected sub for user: #{@user.id} undefined")

        describe 'when basic_subscription product exists for user', ->
          beforeEach utils.wrap ->
            @product = Product({name: 'basic_subscription', gems: 20})
            yield @product.save()

          describe 'when no previous payment recorded', ->
            beforeEach utils.wrap ->
              yield utils.clearModels([Payment])

            it 'creates a new payment and awards gems', utils.wrap ->
              url = getURL('/paypal/webhook')
              [res, body] = yield request.postAsync({ uri: url, json: @paymentEventData })
              expect(res.statusCode).toEqual(200)
              payment = yield Payment.findOne({'payPalSale.id': @paymentEventData.resource.id})
              expect(payment).toBeTruthy()
              expect(payment.get('purchaser').toString()).toEqual(@user.id)
              expect(payment.get('amount')).toEqual(Math.round(parseFloat(@paymentEventData.resource.amount.total) * 100))
              user = yield User.findById(payment.get('purchaser'))
              expect(user.get('purchased').gems).toBeDefined() # Products in db are not predictable for this test suite

          describe 'when previous payment already recorded', ->
            beforeEach utils.wrap ->
              yield utils.clearModels([Payment])
              yield Payment({'payPalSale.id': @paymentEventData.resource.id}).save()
              payments = yield Payment.find({'payPalSale.id': @paymentEventData.resource.id}).lean()
              expect(payments?.length).toEqual(1)

            it 'does not create a new payment', utils.wrap ->
              url = getURL('/paypal/webhook')
              [res, body] = yield request.postAsync({ uri: url, json: @paymentEventData })
              expect(res.statusCode).toEqual(200)
              expect(res.body).toEqual("Payment already recorded for #{@paymentEventData.resource.id}")
              payments = yield Payment.find({'payPalSale.id': @paymentEventData.resource.id}).lean()
              expect(payments?.length).toEqual(1)

          describe 'when initial subscribe payment already recorded', ->
            beforeEach utils.wrap ->
              yield utils.clearModels([Payment])
              @payment = yield Payment({'payPalBillingAgreementID': @paymentEventData.resource.billing_agreement_id}).save()
              payments = yield Payment.find({'payPalBillingAgreementID': @paymentEventData.resource.billing_agreement_id}).lean()
              expect(payments?.length).toEqual(1)

            it 'does not create a new payment and updates the existing one for the corresponding webhook call', utils.wrap ->
              url = getURL('/paypal/webhook')
              [res, body] = yield request.postAsync({ uri: url, json: @paymentEventData })
              expect(res.statusCode).toEqual(200)
              expect(res.body).toEqual("Payment sale object #{@paymentEventData.resource.id} added to initial payment #{@payment.id}")
              payments = yield Payment.find({'payPalSale.id': @paymentEventData.resource.id}).lean()
              expect(payments?.length).toEqual(1)
              expect(payments[0].payPalBillingAgreementID).toEqual(@paymentEventData.resource.billing_agreement_id)

            describe 'when initial subscribe payment already updated from webhook', ->
              beforeEach utils.wrap ->
                url = getURL('/paypal/webhook')
                [res, body] = yield request.postAsync({ uri: url, json: @paymentEventData })
                expect(res.statusCode).toEqual(200)
                expect(res.body).toEqual("Payment sale object #{@paymentEventData.resource.id} added to initial payment #{@payment.id}")
                payments = yield Payment.find({'payPalSale.id': @paymentEventData.resource.id}).lean()
                expect(payments?.length).toEqual(1)
                expect(payments[0].payPalBillingAgreementID).toEqual(@paymentEventData.resource.billing_agreement_id)

              it 'creates a 2nd payment for month 2 recurring payment', utils.wrap ->
                secondPaymentData = _.cloneDeep(@paymentEventData)
                secondPaymentData.resource.id += 'second'
                url = getURL('/paypal/webhook')
                [res, body] = yield request.postAsync({ uri: url, json: secondPaymentData })
                expect(res.statusCode).toEqual(200)
                payments = yield Payment.find({'payPalSale.id': secondPaymentData.resource.id}).lean()
                expect(payments?.length).toEqual(1)
                expect(payments[0].payPalBillingAgreementID).not.toBeDefined()

  describe 'when BILLING.SUBSCRIPTION.CANCELLED event', ->
    beforeEach utils.wrap ->
      @paymentEventData = {
        "id": "WH-6TD369808N914414D-1YJ376786E892292F",
        "create_time": "2016-04-28T11:53:10Z",
        "resource_type": "Agreement",
        "event_type": "BILLING.SUBSCRIPTION.CANCELLED",
        "summary": "A billing subscription was cancelled",
        "resource": {
          "shipping_address": {
            "recipient_name": "Cool Buyer",
            "line1": "3rd st",
            "line2": "cool",
            "city": "San Jose",
            "state": "CA",
            "postal_code": "95112",
            "country_code": "US"
          },
          "id": "I-PE7JWXKGVN0R",
          "plan": {
            "curr_code": "USD",
            "links": [],
            "payment_definitions": [
              {
                "type": "TRIAL",
                "frequency": "Month",
                "frequency_interval": "1",
                "amount": {
                  "value": "5.00"
                },
                "cycles": "5",
                "charge_models": [
                  {
                    "type": "TAX",
                    "amount": {
                      "value": "1.00"
                    }
                  },
                  {
                    "type": "SHIPPING",
                    "amount": {
                      "value": "1.00"
                    }
                  }
                ]
              },
              {
                "type": "REGULAR",
                "frequency": "Month",
                "frequency_interval": "1",
                "amount": {
                  "value": "10.00"
                },
                "cycles": "15",
                "charge_models": [
                  {
                    "type": "TAX",
                    "amount": {
                      "value": "2.00"
                    }
                  },
                  {
                    "type": "SHIPPING",
                    "amount": {
                      "value": "1.00"
                    }
                  }
                ]
              }
            ],
            "merchant_preferences": {
              "setup_fee": {
                "value": "0.00"
              },
              "auto_bill_amount": "YES",
              "max_fail_attempts": "21"
            }
          },
          "payer": {
            "payment_method": "paypal",
            "status": "verified",
            "payer_info": {
              "email": "coolbuyer@example.com",
              "first_name": "Cool",
              "last_name": "Buyer",
              "payer_id": "XLHKRXRA4H7QY",
              "shipping_address": {
                "recipient_name": "Cool Buyer",
                "line1": "3rd st",
                "line2": "cool",
                "city": "San Jose",
                "state": "CA",
                "postal_code": "95112",
                "country_code": "US"
              }
            }
          },
          "description": "update desc",
          "agreement_details": {
            "outstanding_balance": {
              "value": "0.00"
            },
            "num_cycles_remaining": "5",
            "num_cycles_completed": "0",
            "last_payment_date": "2016-04-28T11:29:54Z",
            "last_payment_amount": {
              "value": "1.00"
            },
            "final_payment_due_date": "2017-11-30T10:00:00Z",
            "failed_payment_count": "0"
          },
          "state": "Cancelled",
          "links": [
            {
              "href": "https://api.paypal.com/v1/payments/billing-agreements/I-PE7JWXKGVN0R",
              "rel": "self",
              "method": "GET"
            }
          ],
          "start_date": "2016-04-30T07:00:00Z"
        },
        "links": [
          {
            "href": "https://api.paypal.com/v1/notifications/webhooks-events/WH-6TD369808N914414D-1YJ376786E892292F",
            "rel": "self",
            "method": "GET",
            "encType": "application/json"
          },
          {
            "href": "https://api.paypal.com/v1/notifications/webhooks-events/WH-6TD369808N914414D-1YJ376786E892292F/resend",
            "rel": "resend",
            "method": "POST",
            "encType": "application/json"
          }
        ],
        "event_version": "1.0"
      }

    describe 'when incomplete', ->

      it 'returns 200 and incomplete message', utils.wrap ->
        @paymentEventData.resource.state = 'incomplete'
        url = getURL('/paypal/webhook')
        [res, body] = yield request.postAsync({ uri: url, json: {event_type: "BILLING.SUBSCRIPTION.CANCELLED"}})
        expect(res.statusCode).toEqual(200)
        expect(res.body).toEqual("PayPal webhook subscription cancellation, no billing agreement given for #{@paymentEventData.event_type} #{JSON.stringify({event_type: "BILLING.SUBSCRIPTION.CANCELLED"})}")

    describe 'when no user with billing agreement', ->

      it 'returns 200 and no user message', utils.wrap ->
        url = getURL('/paypal/webhook')
        [res, body] = yield request.postAsync({ uri: url, json: @paymentEventData })
        expect(res.statusCode).toEqual(200)
        expect(res.body).toEqual("PayPal webhook subscription cancellation, no billing agreement for #{@paymentEventData.resource.id}")

    describe 'when user with billing agreement', ->
      beforeEach utils.wrap ->
        @user = yield utils.initUser()
        yield utils.loginUser(@user)
        @user.set('payPal.billingAgreementID', @paymentEventData.resource.id)
        yield @user.save()

      it 'unsubscribes user and returns 200', utils.wrap ->
        url = getURL('/paypal/webhook')
        [res, body] = yield request.postAsync({ uri: url, json: @paymentEventData })
        expect(res.statusCode).toEqual(200)
        user = yield User.findById @user.id
        expect(user.get('payPal.billingAgreementID')).not.toBeDefined()
        expect(user.hasSubscription()).toBeTruthy()
        expect(new Date(user.get('stripe').free)).toBeGreaterThan(new Date())
