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

  it 'denies username-only users trying to subscribe', utils.wrap (done) ->
    user = yield utils.initUser({ email: undefined,  })
    yield utils.loginUser(user)
    [res, body] = yield request.putAsync(getURL("/db/user/#{user.id}"), { headers, json: { stripe: { planID: 'basic', token: '12345' } } })
    expect(res.statusCode).toBe(403)
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

  describe 'APIs', ->
    # TODO: Refactor these tests to be use yield, be independent of one another, and move to products.spec.coffee
    subscriptionURL = getURL('/db/subscription')
    purchaseYearSaleUrl = null
    beforeEach utils.wrap (done) ->
      yield utils.populateProducts()
      product = yield Product.findOne({name: 'year_subscription'})
      purchaseYearSaleUrl = getURL("/db/products/#{product.id}/purchase")
      done()

    it 'year_sale', (done) ->
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
            request.post {uri: purchaseYearSaleUrl, json: requestBody, headers: headers }, (err, res) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(200)
              User.findById user1.id, (err, user1) ->
                expect(err).toBeNull()
                stripeInfo = user1.get('stripe')
                expect(stripeInfo).toBeDefined()
                return done() unless stripeInfo
                endDate = new Date()
                endDate.setUTCFullYear(endDate.getUTCFullYear() + 1)
                expect(stripeInfo.free).toEqual(endDate.toISOString().substring(0, 10))
                expect(stripeInfo.customerID).toBeDefined()
                expect(user1.get('purchased')?.gems).toEqual(subGems*12)
                Payment.findOne 'stripe.customerID': stripeInfo.customerID, (err, payment) ->
                  expect(err).toBeNull()
                  expect(payment).toBeTruthy()
                  expect(payment.get('gems')).toEqual(subGems*12)
                  nockDone()
                  done()

    it 'year_sale when stripe.free === true', (done) ->
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
              request.post {uri: purchaseYearSaleUrl, json: requestBody, headers: headers }, (err, res) ->
                expect(err).toBeNull()
                expect(res.statusCode).toBe(200)
                User.findById user1.id, (err, user1) ->
                  expect(err).toBeNull()
                  stripeInfo = user1.get('stripe')
                  expect(stripeInfo).toBeDefined()
                  return done() unless stripeInfo
                  endDate = new Date()
                  endDate.setUTCFullYear(endDate.getUTCFullYear() + 1)
                  expect(stripeInfo.free).toEqual(endDate.toISOString().substring(0, 10))
                  expect(stripeInfo.customerID).toBeDefined()
                  expect(user1.get('purchased')?.gems).toEqual(subGems*12)
                  Payment.findOne 'stripe.customerID': stripeInfo.customerID, (err, payment) ->
                    expect(err).toBeNull()
                    expect(payment).toBeTruthy()
                    expect(payment.get('gems')).toEqual(subGems*12)
                    nockDone()
                    done()

    it 'year_sale when stripe.free < today', (done) ->
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
              request.post {uri: purchaseYearSaleUrl, json: requestBody, headers: headers }, (err, res) ->
                expect(err).toBeNull()
                expect(res.statusCode).toBe(200)
                User.findById user1.id, (err, user1) ->
                  expect(err).toBeNull()
                  stripeInfo = user1.get('stripe')
                  expect(stripeInfo).toBeDefined()
                  return done() unless stripeInfo
                  endDate = new Date()
                  endDate.setUTCFullYear(endDate.getUTCFullYear() + 1)
                  expect(stripeInfo.free).toEqual(endDate.toISOString().substring(0, 10))
                  expect(stripeInfo.customerID).toBeDefined()
                  expect(user1.get('purchased')?.gems).toEqual(subGems*12)
                  Payment.findOne 'stripe.customerID': stripeInfo.customerID, (err, payment) ->
                    expect(err).toBeNull()
                    expect(payment).toBeTruthy()
                    expect(payment.get('gems')).toEqual(subGems*12)
                    nockDone()
                    done()

    it 'year_sale when stripe.free > today', (done) ->
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
              request.post {uri: purchaseYearSaleUrl, json: requestBody, headers: headers }, (err, res) ->
                expect(err).toBeNull()
                expect(res.statusCode).toBe(200)
                User.findById user1.id, (err, user1) ->
                  expect(err).toBeNull()
                  stripeInfo = user1.get('stripe')
                  expect(stripeInfo).toBeDefined()
                  return done() unless stripeInfo
                  endDate = new Date()
                  endDate.setUTCFullYear(endDate.getUTCFullYear() + 1)
                  endDate.setUTCDate(endDate.getUTCDate() + 5)
                  expect(stripeInfo.free).toEqual(endDate.toISOString().substring(0, 10))
                  expect(stripeInfo.customerID).toBeDefined()
                  expect(user1.get('purchased')?.gems).toEqual(subGems*12)
                  Payment.findOne 'stripe.customerID': stripeInfo.customerID, (err, payment) ->
                    expect(err).toBeNull()
                    expect(payment).toBeTruthy()
                    expect(payment.get('gems')).toEqual(subGems*12)
                    nockDone()
                    done()

    it 'year_sale with monthly sub', (done) ->
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
                    request.post {uri: purchaseYearSaleUrl, json: requestBody, headers: headers }, (err, res) ->
                      expect(err).toBeNull()
                      expect(res.statusCode).toBe(200)
                      User.findById user1.id, (err, user1) ->
                        expect(err).toBeNull()
                        stripeInfo = user1.get('stripe')
                        expect(stripeInfo).toBeDefined()
                        return done() unless stripeInfo
                        endDate = stripeSubscriptionPeriodEndDate
                        endDate.setUTCFullYear(endDate.getUTCFullYear() + 1)
                        expect(stripeInfo.free).toEqual(endDate.toISOString().substring(0, 10))
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

    
