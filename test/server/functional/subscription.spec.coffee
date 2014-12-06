
config = require '../../../server_config'
require '../common'

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
      subtotal: 999,
      total: 999,
      customer: 'cus_5Fz9MVWP2bDPGV',
      object: 'invoice',
      attempted: true,
      closed: true,
      forgiven: false,
      paid: true,
      livemode: false,
      attempt_count: 1,
      amount_due: 999,
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
  api_version: '2014-11-05'
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
  api_version: '2014-11-05'
}


describe '/db/user, editing stripe property', ->

  stripe = require('stripe')(config.stripe.secretKey)
  userURL = getURL('/db/user')
  webhookURL = getURL('/stripe/webhook')
  headers = {'X-Change-Plan': 'true'}

  it 'clears the db first', (done) ->
    clearModels [User, Payment], (err) ->
      throw err if err
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
          done()
          
  it 'creates a subscription when you put a token and plan', (done) ->
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
          expect(joeData.purchased.gems).toBe(3500)
          expect(joeData.stripe.customerID).toBeDefined()
          expect(firstSubscriptionID = joeData.stripe.subscriptionID).toBeDefined()
          expect(joeData.stripe.planID).toBe('basic')
          expect(joeData.stripe.token).toBeUndefined()
          done()
          
  it 'records a payment through the webhook', (done) ->
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
            expect(user.get('purchased').gems).toBe(3500)
            done()
 
  it 'schedules the stripe subscription to be cancelled when stripe.planID is removed from the user', (done) ->
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
        done()

  
  it 'allows you to sign up again using the same customer ID as before, no token necessary', (done) ->
    joeData.stripe.planID = 'basic'
    request.put {uri: userURL, json: joeData, headers: headers }, (err, res, body) ->
      joeData = body
    
      expect(res.statusCode).toBe(200)
      expect(joeData.stripe.customerID).toBeDefined()
      expect(joeData.stripe.subscriptionID).toBeDefined()
      expect(joeData.stripe.subscriptionID).not.toBe(firstSubscriptionID)
      expect(joeData.stripe.planID).toBe('basic')
      done()
      
  it 'will not have immediately created new payments when signing back up from a cancelled subscription', (done) ->
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
            expect(user.get('purchased').gems).toBe(3500)
            done()

  it 'deletes the subscription from the user object when an event about it comes through the webhook', (done) ->
    stripe.customers.retrieveSubscription joeData.stripe.customerID, joeData.stripe.subscriptionID, (err, subscription) ->
      event = _.cloneDeep(customerSubscriptionDeletedSampleEvent)
      event.data.object = subscription
      request.post {uri: webhookURL, json: event}, (err, res, body) ->
        User.findById joeData._id, (err, user) ->
          expect(user.get('purchased').gems).toBe(3500)
          expect(user.get('stripe').subscriptionID).toBeUndefined()
          expect(user.get('stripe').planID).toBeUndefined()
          done()
          
  it "updates the customer's email when you change the user's email", (done) ->
    joeData.email = 'newEmail@gmail.com'
    request.put {uri: userURL, json: joeData, headers: headers }, (err, res, body) ->
      f = -> stripe.customers.retrieve joeData.stripe.customerID, (err, customer) ->
        expect(customer.email).toBe('newEmail@gmail.com')
        done()
      setTimeout(f, 500) # bit of a race condition here, response returns before stripe has been updated
