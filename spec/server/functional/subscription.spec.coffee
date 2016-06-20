async = require 'async'
config = require '../../../server_config'
require '../common'
utils = require '../../../app/core/utils' # Must come after require /common
mongoose = require 'mongoose'
TRAVIS = process.env.COCO_TRAVIS_TEST
nockUtils = require '../nock-utils'
User = require '../../../server/models/User'
Payment = require '../../../server/models/Payment'
Prepaid = require '../../../server/models/Prepaid'
request = require '../request'

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
        expect(res.statusCode).toBe 403
        done()

  #- shared data between tests
  joeData = null
  firstSubscriptionID = null

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
  afterEach nockUtils.teardownNock

  # Start helpers

  getSubscribedQuantity = (numSponsored) ->
    return 0 if numSponsored < 1
    if numSponsored <= 10
      Math.round(numSponsored  * subPrice * 0.8)
    else
      Math.round(10 * subPrice * 0.8 + (numSponsored - 10) * subPrice * 0.6)

  getUnsubscribedQuantity = (numSponsored) ->
    return 0 if numSponsored < 1
    if numSponsored <= 1
      subPrice
    else if numSponsored <= 11
      Math.round(subPrice + (numSponsored - 1) * subPrice * 0.8)
    else
      Math.round(subPrice + 10 * subPrice * 0.8 + (numSponsored - 11) * subPrice * 0.6)

  verifyNotRecipient = (userID, done) ->
    User.findById userID, (err, user) ->
      expect(err).toBeNull()
      if stripeInfo = user.get('stripe')
        expect(stripeInfo.sponsorID).toBeUndefined()
      done()

  verifyNotSponsoring = (sponsorID, recipientID, done) ->
    # console.log 'verifyNotSponsoring', sponsorID, recipientID
    User.findById sponsorID, (err, sponsor) ->
      expect(err).toBeNull()
      expect(sponsor).not.toBeNull()
      return done() unless sponsor
      stripeInfo = sponsor.get('stripe')
      return done() unless stripeInfo?.customerID?
      checkSubscriptions = (starting_after, done) ->
        options = {}
        options.starting_after = starting_after if starting_after
        stripe.customers.listSubscriptions stripeInfo.customerID, options, (err, subscriptions) ->
          expect(err).toBeNull()
          for subscription in subscriptions.data
            if subscription.plan.id is 'basic'
              expect(subscription.metadata.id).not.toEqual(recipientID)
            if subscription.plan.id is 'incremental'
              expect(subscription.metadata.id).toEqual(sponsorID)
          if subscriptions.has_more
            checkSubscriptions subscriptions.data[subscriptions.data.length - 1].id, done
          else
            done()
      checkSubscriptions null, done

  verifySponsorship = (sponsorUserID, sponsoredUserID, done) ->
    # console.log 'verifySponsorship', sponsorUserID, sponsoredUserID
    User.findById sponsorUserID, (err, user) ->
      expect(err).toBeNull()
      expect(user).not.toBeNull()
      return done() unless user
      sponsorStripe = user.get('stripe')
      sponsorCustomerID = sponsorStripe.customerID
      numSponsored = sponsorStripe.recipients?.length
      expect(sponsorCustomerID).toBeDefined()
      expect(sponsorStripe.sponsorSubscriptionID).toBeDefined()
      expect(sponsorStripe.token).toBeUndefined()
      expect(numSponsored).toBeGreaterThan(0)

      # Verify Stripe sponsor subscription data
      return done() unless sponsorCustomerID and sponsorStripe.sponsorSubscriptionID
      stripe.customers.retrieveSubscription sponsorCustomerID, sponsorStripe.sponsorSubscriptionID, (err, subscription) ->
        expect(err).toBeNull()
        expect(subscription?).toBe(true)
        return done() unless subscription?
        expect(subscription.plan.amount).toEqual(1)
        expect(subscription.customer).toEqual(sponsorCustomerID)
        expect(subscription.quantity).toEqual(utils.getSponsoredSubsAmount(subPrice, numSponsored, sponsorStripe.subscriptionID?))

        # Verify sponsor payment
        # May be greater than expected amount due to multiple subscribes and unsubscribes
        paymentQuery =
          purchaser: mongoose.Types.ObjectId(sponsorUserID)
          recipient: mongoose.Types.ObjectId(sponsorUserID)
          "stripe.customerID": sponsorCustomerID
          "stripe.subscriptionID": sponsorStripe.sponsorSubscriptionID
        expectedAmount = utils.getSponsoredSubsAmount(subPrice, numSponsored, sponsorStripe.subscriptionID?)
        Payment.find paymentQuery, (err, payments) ->
          expect(err).toBeNull()
          expect(payments).not.toBeNull()
          amount = 0
          for payment in payments
            amount += payment.get('amount')
            expect(payment.get('gems')).toBeUndefined()

          # NOTE: this amount may be greater than the expected amount due to proration accumlation
          # NOTE: during localy execution, this is usually only 1-2 cents
          expect(amount).toBeGreaterThan(expectedAmount - 50)

          # Find recipient info from sponsor stripe data
          for r in sponsorStripe.recipients
            if r.userID is sponsoredUserID
              recipientInfo = r
              break
          expect(recipientInfo).toBeDefined()
          expect(recipientInfo.subscriptionID).toBeDefined()
          expect(recipientInfo.subscriptionID).not.toEqual(sponsorStripe.sponsorSubscriptionID)
          expect(recipientInfo.couponID).toEqual('free')

          # Verify Stripe recipient subscription data
          return done() unless sponsorCustomerID and recipientInfo.subscriptionID
          stripe.customers.retrieveSubscription sponsorCustomerID, recipientInfo.subscriptionID, (err, subscription) ->
            expect(err).toBeNull()
            expect(subscription.plan.amount).toEqual(subPrice)
            expect(subscription.customer).toEqual(sponsorCustomerID)
            expect(subscription.quantity).toEqual(1)
            expect(subscription.metadata.id).toEqual(sponsoredUserID)
            expect(subscription.discount.coupon.id).toEqual(recipientInfo.couponID)

            # Verify recipient internal data
            User.findById sponsoredUserID, (err, recipient) ->
              expect(err).toBeNull()
              stripeInfo = recipient.get('stripe')
              expect(stripeInfo.sponsorID).toEqual(sponsorUserID)
              unless stripeInfo.sponsorSubscriptionID?
                expect(stripeInfo.customerID).toBeUndefined()
              expect(stripeInfo.token).toBeUndefined()
              expect(recipient.get('purchased').gems).toBeGreaterThan(subGems - 1)
              expect(recipient.isPremium()).toEqual(true)

              # Verify recipient payment
              # TODO: Not accurate enough when resubscribing a user
              paymentQuery =
                purchaser: mongoose.Types.ObjectId(sponsorUserID)
                recipient: mongoose.Types.ObjectId(sponsoredUserID)
                "stripe.customerID": sponsorCustomerID
              Payment.findOne paymentQuery, (err, payment) ->
                expect(err).toBeNull()
                expect(payment).not.toBeNull()
                return done() if payment is null
                expect(payment.get('amount')).toEqual(0)
                expect(payment.get('gems')).toBeGreaterThan(subGems - 1)
                done()

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

  subscribeRecipients = (sponsor, recipients, token, done) ->
    # console.log 'subscribeRecipients', sponsor.id, (recipient.id for recipient in recipients), token?
    requestBody = sponsor.toObject()
    requestBody.stripe =
      subscribeEmails: (recipient.get('email') for recipient in recipients)
    requestBody.stripe.token = token.id if token?
    request.put {uri: userURL, json: requestBody, headers: headers }, (err, res, body) ->
      expect(err).toBeNull()
      return done() if err
      expect(res.statusCode).toBe(200)
      expect(body.stripe?.customerID).toBeDefined()
      updatedUser = body

      # Call webhooks for invoices
      options = customer: body.stripe?.customerID, limit: 100
      stripe.invoices.list options, (err, invoices) ->
        expect(err).toBeNull()
        expect(invoices).not.toBeNull()
        return done(updatedUser) unless invoices?
        expect(invoices.has_more).toEqual(false)
        makeWebhookCall = (invoice) ->
          (callback) ->
            event = _.cloneDeep(invoiceChargeSampleEvent)
            event.data.object = invoice
            # console.log 'Calling webhook', event.type, invoice.id
            request.post {uri: webhookURL, json: event}, (err, res, body) ->
              callback err
        webhookTasks = []
        for invoice in invoices.data
          unless invoice.id of invoicesWebHooked
            invoicesWebHooked[invoice.id] = true
            webhookTasks.push makeWebhookCall(invoice)
        async.series webhookTasks, (err, results) ->
          expect(err?).toEqual(false)
          done(updatedUser)

  unsubscribeRecipient = (sponsor, recipient, done) ->
    # console.log 'unsubscribeRecipient', sponsor.id, recipient.id
    stripeInfo = sponsor.get('stripe')
    customerID = stripeInfo.customerID
    expect(stripeInfo.recipients).toBeDefined()
    return done() unless stripeInfo.recipients
    for r in stripeInfo.recipients
      if r.userID is recipient.id
        subscriptionID = r.subscriptionID
        break
    expect(customerID).toBeDefined()
    expect(subscriptionID).toBeDefined()

    # Find Stripe subscription
    stripe.customers.retrieveSubscription customerID, subscriptionID, (err, subscription) ->
      expect(err).toBeNull()
      expect(subscription).not.toBeNull()

      # Call unsubscribe API
      requestBody = sponsor.toObject()
      requestBody.stripe = unsubscribeEmail: recipient.get('email')
      request.put {uri: userURL, json: requestBody, headers: headers }, (err, res, body) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe(200)
        done()

  # Subscribe a bunch of recipients at once, used for bulk discount testing
  class SubbedRecipients
    constructor: (@count, @toVerify) ->
      @index = 0
      @recipients = []

    length: ->
      @recipients.length

    get: (i) ->
      @recipients[i]

    createRecipients: (done) ->
      return done() if @recipients.length is @count
      createNewUser (user) =>
        @recipients.push user
        @createRecipients done

    subRecipients: (user1, token=null, done) ->
      # console.log 'subRecipients', user1.id, @recipients.length
      User.findById user1.id, (err, user1) =>
        subscribeRecipients user1, @recipients, token, (updatedUser) =>
          verifyIndex = 0
          verify = =>
            return done(updatedUser) if verifyIndex >= @toVerify.length
            verifySponsorship user1.id, @recipients[verifyIndex].id, =>
              verifyIndex++
              verify()
          verify()

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

  describe 'Sponsored', ->
    it 'Unsubscribed user1 subscribes user2', (done) ->
      nockUtils.setupNock 'sub-test-13.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          createNewUser (user2) ->
            loginNewUser (user1) ->
              subscribeRecipients user1, [user2], token, (updatedUser) ->
                verifySponsorship user1.id, user2.id, ->
                  nockDone()
                  done()


    it 'Recipient user delete unsubscribes', (done) ->
      nockUtils.setupNock 'sub-test-14.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          createNewUser (user2) ->
            loginNewUser (user1) ->
              subscribeRecipients user1, [user2], token, (updatedUser) ->
                expect(updatedUser).not.toBeNull()
                return done() unless updatedUser
                customerID = updatedUser.stripe?.customerID
                expect(customerID).toBeDefined()
                subscriptionID = updatedUser.stripe?.recipients[0]?.subscriptionID
                expect(subscriptionID).toBeDefined()
                return done() unless customerID and subscriptionID
                loginUser user2, (user2) ->
                  request.del {uri: "#{userURL}/#{user2.id}"}, (err, res) ->
                    expect(err).toBeNull()
                    stripe.customers.retrieveSubscription customerID, subscriptionID, (err, subscription) ->
                      expect(err).not.toBeNull()
                      expect(subscription).toBeNull()
                      User.findById user1.id, (err, user1) ->
                        expect(err).toBeNull()
                        expect(_.isEmpty(user1.get('stripe').recipients))
                        stripe.customers.retrieveSubscription customerID, user1.get('stripe').sponsorSubscriptionID, (err, subscription) ->
                          expect(err).toBeNull()
                          expect(subscription.quantity).toEqual(0)
                          nockDone()
                          done()

    it 'Subscribed user1 subscribes user2, one token', (done) ->
      nockUtils.setupNock 'sub-test-15.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          createNewUser (user2) ->
            loginNewUser (user1) ->
              subscribeUser user1, token, null, (updatedUser) ->
                User.findById user1.id, (err, user1) ->
                  expect(err).toBeNull()
                  subscribeRecipients user1, [user2], null, (updatedUser) ->
                    User.findById user1.id, (err, user1) ->
                      expect(err).toBeNull()
                      expect(user1.get('stripe').subscriptionID).toBeDefined()
                      expect(user1.isPremium()).toEqual(true)
                      verifySponsorship user1.id, user2.id, ->
                        nockDone()
                        done()

    it 'Clean up sponsorships upon sub cancel after setup sponsor sub fails', (done) ->
      nockUtils.setupNock 'sub-test-16.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          createNewUser (user2) ->
            loginNewUser (user1) ->
              subscribeUser user1, token, null, (updatedUser) ->
                User.findById user1.id, (err, user1) ->
                  expect(err).toBeNull()
                  subscribeRecipients user1, [user2], null, (updatedUser) ->

                    # Delete user1 sponsorSubscriptionID to simulate failed sponsor sub
                    User.findById user1.id, (err, user1) ->
                      expect(err).toBeNull()
                      stripeInfo = _.cloneDeep(user1.get('stripe') ? {})
                      delete stripeInfo.sponsorSubscriptionID
                      user1.set 'stripe', stripeInfo
                      user1.save (err, user1) ->
                        expect(err).toBeNull()

                        User.findById user1.id, (err, user1) ->
                          unsubscribeRecipient user1, user2, ->
                            User.findById user1.id, (err, user1) ->
                              expect(err).toBeNull()
                              expect(user1.get('stripe').subscriptionID).toBeDefined()
                              expect(_.isEmpty(user1.get('stripe').recipients)).toEqual(true)
                              expect(user1.isPremium()).toEqual(true)
                              User.findById user2.id, (err, user2) ->
                                verifyNotSponsoring user1.id, user2.id, ->
                                  verifyNotRecipient user2.id, ->
                                    nockDone()
                                    done()


    it 'Unsubscribed user1 unsubscribes user2 and their sub ends', (done) ->
      nockUtils.setupNock 'sub-test-17.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          createNewUser (user2) ->
            loginNewUser (user1) ->
              subscribeRecipients user1, [user2], token, (updatedUser) ->
                User.findById user1.id, (err, user1) ->
                  unsubscribeRecipient user1, user2, ->
                    verifyNotSponsoring user1.id, user2.id, ->
                      verifyNotRecipient user2.id, ->
                        nockDone()
                        done()


    it 'Unsubscribed user1 immediately resubscribes user2, one token', (done) ->
      nockUtils.setupNock 'sub-test-18.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          createNewUser (user2) ->
            loginNewUser (user1) ->
              subscribeRecipients user1, [user2], token, (updatedUser) ->
                User.findById user1.id, (err, user1) ->
                  unsubscribeRecipient user1, user2, ->
                    subscribeRecipients user1, [user2], null, (updatedUser) ->
                      verifySponsorship user1.id, user2.id, ->
                        nockDone()
                        done()

    it 'Sponsored user2 subscribes their sponsor user1', (done) ->
      nockUtils.setupNock 'sub-test-19.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          createNewUser (user2) ->
            loginNewUser (user1) ->
              subscribeRecipients user1, [user2], token, (updatedUser) ->
               loginUser user2, (user2) ->
                  stripe.tokens.create {
                    card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
                  }, (err, token) ->
                    subscribeRecipients user2, [user1], token, (updatedUser) ->
                      verifySponsorship user1.id, user2.id, ->
                        verifySponsorship user2.id, user1.id, ->
                          nockDone()
                          done()

    it 'Unsubscribed user1 subscribes user1', (done) ->
      nockUtils.setupNock 'sub-test-20.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->

            requestBody = user1.toObject()
            requestBody.stripe =
              subscribeEmails: [user1.get('email')]
              token: token.id
            request.put {uri: userURL, json: requestBody, headers: headers }, (err, res, body) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(200)

              User.findById user1.id, (err, user) ->
                expect(err).toBeNull()
                stripeInfo = user.get('stripe')
                expect(stripeInfo.customerID).toBeDefined()
                expect(stripeInfo.planID).toBeUndefined()
                expect(stripeInfo.subscriptionID).toBeUndefined()
                expect(stripeInfo.recipients.length).toEqual(0)
                nockDone()
                done()

    it 'Subscribed user1 unsubscribes user2', (done) ->
      nockUtils.setupNock 'sub-test-21.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          createNewUser (user2) ->
            loginNewUser (user1) ->
              subscribeUser user1, token, null, (updatedUser) ->
                User.findById user1.id, (err, user1) ->
                  expect(err).toBeNull()
                  subscribeRecipients user1, [user2], null, (updatedUser) ->
                    User.findById user1.id, (err, user1) ->
                      unsubscribeRecipient user1, user2, ->
                        User.findById user1.id, (err, user1) ->
                          expect(err).toBeNull()
                          expect(user1.get('stripe').subscriptionID).toBeDefined()
                          expect(user1.isPremium()).toEqual(true)
                          User.findById user2.id, (err, user2) ->
                            verifyNotSponsoring user1.id, user2.id, ->
                              verifyNotRecipient user2.id, ->
                                nockDone()
                                done()

    it 'Subscribed user1 subscribes user2, unsubscribes themselves', (done) ->
      nockUtils.setupNock 'sub-test-22.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          createNewUser (user2) ->
            loginNewUser (user1) ->
              subscribeUser user1, token, null, (updatedUser) ->
                User.findById user1.id, (err, user1) ->
                  expect(err).toBeNull()
                  subscribeRecipients user1, [user2], null, (updatedUser) ->
                    User.findById user1.id, (err, user1) ->
                      unsubscribeUser user1, ->
                        verifySponsorship user1.id, user2.id, ->
                          nockDone()
                          done()

    it 'Sponsored user2 tries to subscribe', (done) ->
      nockUtils.setupNock 'sub-test-23.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          createNewUser (user2) ->
            loginNewUser (user1) ->
              subscribeRecipients user1, [user2], token, (updatedUser) ->
                 loginUser user2, (user2) ->
                  stripe.tokens.create {
                    card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
                  }, (err, token) ->
                    requestBody = user2.toObject()
                    requestBody.stripe =
                      token: token.id
                      planID: 'basic'
                    request.put {uri: userURL, json: requestBody, headers: headers }, (err, res, body) ->
                      expect(err).toBeNull()
                      expect(res.statusCode).toBe(403)
                      nockDone()
                      done()

    it 'Sponsored user2 tries to subscribe with valid prepaid', (done) ->
      nockUtils.setupNock 'sub-test-24.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          createNewUser (user2) ->
            loginNewUser (user1) ->
              subscribeRecipients user1, [user2], token, (updatedUser) ->
                loginUser user2, (user2) ->
                  user2.set('permissions', ['admin'])
                  user2.save (err, user1) ->
                    expect(err).toBeNull()
                    expect(user2.isAdmin()).toEqual(true)
                    createPrepaid 'subscription', 1, 0, (err, res, prepaid) ->
                      expect(err).toBeNull()
                      requestBody = user2.toObject()
                      requestBody.stripe =
                        planID: 'basic'
                        prepaidCode: prepaid.code
                      request.put {uri: userURL, json: requestBody, headers: headers }, (err, res, body) ->
                        expect(err).toBeNull()
                        expect(res.statusCode).toBe(403)
                        nockDone()
                        done()

    it 'Sponsored user2 tries to unsubscribe', (done) ->
      nockUtils.setupNock 'sub-test-25.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          createNewUser (user2) ->
            loginNewUser (user1) ->
              subscribeRecipients user1, [user2], token, (updatedUser) ->
                loginUser user2, (user2) ->
                  requestBody = user2.toObject()
                  requestBody.stripe =
                    recipient: user2.id
                  request.put {uri: userURL, json: requestBody, headers: headers }, (err, res, body) ->
                    expect(err).toBeNull()
                    expect(res.statusCode).toBe(200)
                    verifySponsorship user1.id, user2.id, ->
                      nockDone()
                      done()

    it 'Cancel sponsor subscription with 2 recipient subscriptions, then subscribe 1 old and 1 new', (done) ->
      nockUtils.setupNock 'sub-test-26.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          createNewUser (user3) ->
            createNewUser (user2) ->
              loginNewUser (user1) ->
                subscribeRecipients user1, [user2, user3], token, (updatedUser) ->
                  customerID = updatedUser?.stripe?.customerID
                  subscriptionID = updatedUser?.stripe?.sponsorSubscriptionID
                  expect(customerID).toBeDefined()
                  expect(subscriptionID).toBeDefined()
                  return done() unless customerID and subscriptionID

                  # Find Stripe sponsor subscription
                  stripe.customers.retrieveSubscription customerID, subscriptionID, (err, subscription) ->
                    expect(err).toBeNull()
                    expect(subscription).not.toBeNull()

                    # Cancel Stripe sponsor subscription
                    stripe.customers.cancelSubscription customerID, subscriptionID, (err) ->
                      expect(err).toBeNull()

                      # Simulate customer.subscription.deleted webhook event for sponsor subscription
                      event = _.cloneDeep(customerSubscriptionDeletedSampleEvent)
                      event.data.object = subscription
                      request.post {uri: webhookURL, json: event}, (err, res, body) ->
                        expect(err).toBeNull()

                        # Should have 2 cancelled recipient subs with cancel_at_period_end = true
                        # TODO: is this correct, or do we terminate recipient subs immediately now?
                        User.findById user1.id, (err, user1) ->
                          expect(err).toBeNull()
                          stripeInfo = user1.get('stripe')
                          expect(stripeInfo.sponsorSubscriptionID).toBeUndefined()
                          expect(stripeInfo.recipients).toBeUndefined()
                          stripe.customers.listSubscriptions stripeInfo.customerID, (err, subscriptions) ->
                            expect(err).toBeNull()
                            expect(subscriptions.data.length).toEqual(2)
                            for sub in subscriptions.data
                              expect(sub.plan.id).toEqual('basic')
                              expect(sub.cancel_at_period_end).toEqual(true)

                            # Subscribe user3 back
                            User.findById user1.id, (err, user1) ->
                              subscribeRecipients user1, [user3], null, (updatedUser) ->
                                verifySponsorship user1.id, user3.id, ->

                                  # Subscribe new user4
                                  createNewUser (user4) ->
                                    loginUser user1, (user1) ->
                                      User.findById user1.id, (err, user1) ->
                                        subscribeRecipients user1, [user4], null, (updatedUser) ->
                                          verifySponsorship user1.id, user4.id, ->
                                            nockDone()
                                            done()

    it 'Subscribing two users separately yields proration payment', (done) ->
      nockUtils.setupNock 'sub-test-27.json', (err, nockDone) ->
        # TODO: Use test plan with low duration + setTimeout to test delay between 2 subscribes
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          createNewUser (user3) ->
            createNewUser (user2) ->
              loginNewUser (user1) ->
                subscribeRecipients user1, [user2], token, (updatedUser) ->
                  User.findById user1.id, (err, user1) ->
                    subscribeRecipients user1, [user3], null, (updatedUser) ->
                      # TODO: What do we expect invoices to show here?
                      stripe.invoices.list {customer: updatedUser.stripe.customerID}, (err, invoices) ->
                        expect(err).toBeNull()

                        # Verify for proration invoice
                        foundProratedInvoice = false
                        for invoice in invoices.data
                          line = invoice.lines.data[0]
                          if line.type is 'invoiceitem' and line.proration
                            totalAmount = utils.getSponsoredSubsAmount(subPrice, 2, false)
                            expect(invoice.total).toBeLessThan(totalAmount)
                            expect(invoice.total).toEqual(totalAmount - subPrice)
                            Payment.findOne "stripe.invoiceID": invoice.id, (err, payment) ->
                              expect(err).toBeNull()
                              expect(payment.get('amount')).toEqual(invoice.total)
                              nockDone()
                              done()
                            foundProratedInvoice = true
                            break
                        unless foundProratedInvoice
                          expect(foundProratedInvoice).toEqual(true)
                          nockDone()
                          done()

    it 'Invalid subscribeEmails', (done) ->
      nockUtils.setupNock 'sub-test-28.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            requestBody = user1.toObject()
            requestBody.stripe =
              subscribeEmails: ['invalid@user.com', 'notemailformat', '', null, undefined]
            requestBody.stripe.token = token.id
            request.put {uri: userURL, json: requestBody, headers: headers }, (err, res, body) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(200)
              expect(body.stripe).toBeDefined()
              User.findById user1.id, (err, sponsor) ->
                expect(err).toBeNull()
                expect(sponsor.get('stripe')).toBeDefined()
                expect(sponsor.get('stripe').customerID).toBeDefined()
                expect(sponsor.get('stripe').sponsorSubscriptionID).toBeDefined()
                expect(sponsor.get('stripe').recipients?.length).toEqual(0)
                nockDone()
                done()

    it 'User1 subscribes user2 then themselves', (done) ->
      nockUtils.setupNock 'sub-test-29.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          createNewUser (user2) ->
            loginNewUser (user1) ->
              subscribeRecipients user1, [user2], token, (updatedUser) ->
                User.findById user1.id, (err, user1) ->
                  expect(err).toBeNull()
                  verifySponsorship user1.id, user2.id, ->

                    stripe.tokens.create {
                      card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
                    }, (err, token) ->
                      subscribeUser user1, token, null, (updatedUser) ->
                        User.findById user1.id, (err, user1) ->
                          expect(err).toBeNull()
                          expect(user1.get('stripe').subscriptionID).toBeDefined()
                          expect(user1.isPremium()).toEqual(true)

                          stripe.customers.listSubscriptions user1.get('stripe').customerID, (err, subscriptions) ->
                            expect(err).toBeNull()
                            expect(subscriptions.data.length).toEqual(3)
                            for sub in subscriptions.data
                              if sub.plan.id is 'basic'
                                if sub.discount?.coupon?.id is 'free'
                                  expect(sub.metadata?.id).toEqual(user2.id)
                                else
                                  expect(sub.metadata?.id).toEqual(user1.id)
                              else
                                expect(sub.plan.id).toEqual('incremental')
                                expect(sub.metadata?.id).toEqual(user1.id)
                            nockDone()
                            done()

    it 'Subscribe with prepaid, then get sponsored', (done) ->
      nockUtils.setupNock 'sub-test-30.json', (err, nockDone) ->
        loginNewUser (user1) ->
          user1.set('permissions', ['admin'])
          user1.save (err, user1) ->
            expect(err).toBeNull()
            expect(user1.isAdmin()).toEqual(true)
            createPrepaid 'subscription', 1, 0, (err, res, prepaid) ->
              expect(err).toBeNull()
              subscribeUser user1, null, prepaid.code, ->
                stripe.tokens.create {
                  card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
                }, (err, token) ->
                  loginNewUser (user2) ->
                    requestBody = user2.toObject()
                    requestBody.stripe =
                      token: token.id
                      subscribeEmails: [user1.get('emailLower')]
                    request.put {uri: userURL, json: requestBody, headers: headers }, (err, res, body) ->
                      expect(err).toBeNull()
                      expect(res.statusCode).toBe(200)
                      User.findById user1.id, (err, user) ->
                        expect(err).toBeNull()
                        stripeInfo = user.get('stripe')
                        expect(stripeInfo.customerID).toBeDefined()
                        expect(stripeInfo.planID).toBeDefined()
                        expect(stripeInfo.subscriptionID).toBeDefined()
                        expect(stripeInfo.sponsorID).toBeUndefined()
                        nockDone()
                        done()


    describe 'Bulk discounts', ->
      # Bulk discount algorithm (includes personal sub):
      # 1 100%
      # 2-11 80%
      # 12+ 60%

      it 'Unsubscribed user1 subscribes two users', (done) ->
        nockUtils.setupNock 'sub-test-31.json', (err, nockDone) ->
          stripe.tokens.create {
            card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
          }, (err, token) ->
            createNewUser (user3) ->
              createNewUser (user2) ->
                loginNewUser (user1) ->
                  subscribeRecipients user1, [user2, user3], token, (updatedUser) ->
                    verifySponsorship user1.id, user2.id, ->
                      verifySponsorship user1.id, user3.id, ->
                        nockDone()
                        done()

      it 'Subscribed user1 subscribes 2 users, unsubscribes 2', (done) ->
        nockUtils.setupNock 'sub-test-32.json', (err, nockDone) ->
          recipientCount = 2
          recipientsToVerify = [0, 1]
          recipients = new SubbedRecipients recipientCount, recipientsToVerify

          # Create recipients
          recipients.createRecipients ->
            expect(recipients.length()).toEqual(recipientCount)

            stripe.tokens.create {
              card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
            }, (err, token) ->

              # Create sponsor user
              loginNewUser (user1) ->
                subscribeUser user1, token, null, (updatedUser) ->
                  User.findById user1.id, (err, user1) ->
                    expect(err).toBeNull()

                    # Subscribe recipients
                    recipients.subRecipients user1, null, ->
                      User.findById user1.id, (err, user1) ->

                        # Unsubscribe recipient0
                        unsubscribeRecipient user1, recipients.get(0), ->
                          User.findById user1.id, (err, user1) ->
                            stripeInfo = user1.get('stripe')
                            expect(stripeInfo.recipients.length).toEqual(1)
                            verifyNotSponsoring user1.id, recipients.get(0).id, ->
                              verifyNotRecipient recipients.get(0).id, ->
                                stripe.customers.retrieveSubscription stripeInfo.customerID, stripeInfo.sponsorSubscriptionID, (err, subscription) ->
                                  expect(err).toBeNull()
                                  expect(subscription).not.toBeNull()
                                  expect(subscription?.quantity).toEqual(getSubscribedQuantity(1))

                                  # Unsubscribe recipient1
                                  unsubscribeRecipient user1, recipients.get(1), ->
                                    User.findById user1.id, (err, user1) ->
                                      stripeInfo = user1.get('stripe')
                                      expect(stripeInfo.recipients.length).toEqual(0)
                                      verifyNotSponsoring user1.id, recipients.get(1).id, ->
                                        verifyNotRecipient recipients.get(1).id, ->
                                          stripe.customers.retrieveSubscription stripeInfo.customerID, stripeInfo.sponsorSubscriptionID, (err, subscription) ->
                                            expect(err).toBeNull()
                                            expect(subscription).not.toBeNull()
                                            return done() unless subscription
                                            expect(subscription.quantity).toEqual(0)
                                            nockDone()
                                            done()

      it 'Subscribed user1 subscribes 3 users, unsubscribes 2, themselves, then 1', (done) ->
        nockUtils.setupNock 'sub-test-33.json', (err, nockDone) ->
          recipientCount = 3
          recipientsToVerify = [0, 1, 2]
          recipients = new SubbedRecipients recipientCount, recipientsToVerify

          # Create recipients
          recipients.createRecipients ->
            expect(recipients.length()).toEqual(recipientCount)
            stripe.tokens.create {
              card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
            }, (err, token) ->

              # Create sponsor user
              loginNewUser (user1) ->
                subscribeUser user1, token, null, (updatedUser) ->
                  User.findById user1.id, (err, user1) ->
                    expect(err).toBeNull()

                    # Subscribe recipients
                    recipients.subRecipients user1, null, ->
                      User.findById user1.id, (err, user1) ->

                        # Unsubscribe first recipient
                        unsubscribeRecipient user1, recipients.get(0), ->
                          User.findById user1.id, (err, user1) ->
                            stripeInfo = user1.get('stripe')
                            expect(stripeInfo.customerID).toBeDefined()
                            expect(stripeInfo.sponsorSubscriptionID).toBeDefined()
                            return done() unless stripeInfo.customerID and stripeInfo.sponsorSubscriptionID
                            expect(stripeInfo.recipients.length).toEqual(recipientCount - 1)
                            verifyNotSponsoring user1.id, recipients.get(0).id, ->
                              verifyNotRecipient recipients.get(0).id, ->
                                stripe.customers.retrieveSubscription stripeInfo.customerID, stripeInfo.sponsorSubscriptionID, (err, subscription) ->
                                  expect(err).toBeNull()
                                  expect(subscription).not.toBeNull()
                                  expect(subscription?.quantity).toEqual(getSubscribedQuantity(recipientCount - 1))

                                  # Unsubscribe second recipient
                                  unsubscribeRecipient user1, recipients.get(1), ->
                                    User.findById user1.id, (err, user1) ->
                                      stripeInfo = user1.get('stripe')
                                      expect(stripeInfo.recipients.length).toEqual(recipientCount - 2)
                                      verifyNotSponsoring user1.id, recipients.get(1).id, ->
                                        verifyNotRecipient recipients.get(1).id, ->
                                          stripe.customers.retrieveSubscription stripeInfo.customerID, stripeInfo.sponsorSubscriptionID, (err, subscription) ->
                                            expect(err).toBeNull()
                                            expect(subscription).not.toBeNull()
                                            expect(subscription?.quantity).toEqual(getSubscribedQuantity(recipientCount - 2))

                                            # Unsubscribe self
                                            User.findById user1.id, (err, user1) ->
                                              unsubscribeUser user1, ->
                                                User.findById user1.id, (err, user1) ->
                                                  stripeInfo = user1.get('stripe')
                                                  expect(stripeInfo.planID).toBeUndefined()

                                                  # Unsubscribe third recipient
                                                  verifySponsorship user1.id, recipients.get(2).id, ->
                                                    unsubscribeRecipient user1, recipients.get(2), ->
                                                      User.findById user1.id, (err, user1) ->
                                                        stripeInfo = user1.get('stripe')
                                                        expect(stripeInfo.recipients.length).toEqual(recipientCount - 3)
                                                        verifyNotSponsoring user1.id, recipients.get(2).id, ->
                                                          verifyNotRecipient recipients.get(2).id, ->
                                                            stripe.customers.retrieveSubscription stripeInfo.customerID, stripeInfo.sponsorSubscriptionID, (err, subscription) ->
                                                              expect(err).toBeNull()
                                                              expect(subscription).not.toBeNull()
                                                              expect(subscription?.quantity).toEqual(getSubscribedQuantity(recipientCount - 3))
                                                              nockDone()
                                                              done()

#      xit 'Unsubscribed user1 subscribes 13 users, unsubcribes 2', (done) ->
#        nockUtils.setupNock 'sub-test-34.json', (err, nockDone) ->
#          # TODO: Hits the Stripe error 'Request rate limit exceeded'.
#          # TODO: Need a better test for 12+ bulk discounts. Or, we could update the bulk disount logic.
#          # TODO: verify interim invoices?
#          recipientCount = 13
#          recipientsToVerify = [0, 1, 10, 11, 12]
#          recipients = new SubbedRecipients recipientCount, recipientsToVerify
#
#          # Create recipients
#          recipients.createRecipients ->
#            expect(recipients.length()).toEqual(recipientCount)
#
#            stripe.tokens.create {
#              card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
#            }, (err, token) ->
#
#              # Create sponsor user
#              loginNewUser (user1) ->
#
#                # Subscribe recipients
#                recipients.subRecipients user1, token, ->
#                  User.findById user1.id, (err, user1) ->
#
#                    # Unsubscribe first recipient
#                    unsubscribeRecipient user1, recipients.get(0), ->
#                      User.findById user1.id, (err, user1) ->
#
#                        stripeInfo = user1.get('stripe')
#                        expect(stripeInfo.recipients.length).toEqual(recipientCount - 1)
#                        verifyNotSponsoring user1.id, recipients.get(0).id, ->
#                          verifyNotRecipient recipients.get(0).id, ->
#                            stripe.customers.retrieveSubscription stripeInfo.customerID, stripeInfo.sponsorSubscriptionID, (err, subscription) ->
#                              expect(err).toBeNull()
#                              expect(subscription).not.toBeNull()
#                              expect(subscription.quantity).toEqual(getUnsubscribedQuantity(recipientCount - 1))
#
#                              # Unsubscribe last recipient
#                              unsubscribeRecipient user1, recipients.get(recipientCount - 1), ->
#                                User.findById user1.id, (err, user1) ->
#                                  stripeInfo = user1.get('stripe')
#                                  expect(stripeInfo.recipients.length).toEqual(recipientCount - 2)
#                                  verifyNotSponsoring user1.id, recipients.get(recipientCount - 1).id, ->
#                                    verifyNotRecipient recipients.get(recipientCount - 1).id, ->
#                                      stripe.customers.retrieveSubscription stripeInfo.customerID, stripeInfo.sponsorSubscriptionID, (err, subscription) ->
#                                        expect(err).toBeNull()
#                                        expect(subscription).not.toBeNull()
#                                        numSponsored = recipientCount - 2
#                                        if numSponsored <= 1
#                                          expect(subscription.quantity).toEqual(subPrice)
#                                        else if numSponsored <= 11
#                                          expect(subscription.quantity).toEqual(subPrice + (numSponsored - 1) * subPrice * 0.8)
#                                        else
#                                          expect(subscription.quantity).toEqual(subPrice + 10 * subPrice * 0.8 + (numSponsored - 11) * subPrice * 0.6)
#                                        nockDone()
#                                        done()

  describe 'APIs', ->
    subscriptionURL = getURL('/db/subscription')

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
            request.put {uri: "#{subscriptionURL}/-/year_sale", json: requestBody, headers: headers }, (err, res) ->
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
              request.put {uri: "#{subscriptionURL}/-/year_sale", json: requestBody, headers: headers }, (err, res) ->
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
              request.put {uri: "#{subscriptionURL}/-/year_sale", json: requestBody, headers: headers }, (err, res) ->
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
              request.put {uri: "#{subscriptionURL}/-/year_sale", json: requestBody, headers: headers }, (err, res) ->
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
                    request.put {uri: "#{subscriptionURL}/-/year_sale", json: requestBody, headers: headers }, (err, res) ->
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

    it 'year_sale with sponsored sub', (done) ->
      nockUtils.setupNock 'sub-test-40.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            user1.set('stripe', {sponsorID: 'dummyID'})
            user1.save (err, user1) ->
              expect(err).toBeNull()
              requestBody =
                stripe:
                  token: token.id
                  timestamp: new Date()
              request.put {uri: "#{subscriptionURL}/-/year_sale", json: requestBody, headers: headers }, (err, res) ->
                expect(err).toBeNull()
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
