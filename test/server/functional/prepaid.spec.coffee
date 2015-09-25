require '../common'
config = require '../../../server_config'
moment = require 'moment'
{findStripeSubscription} = require '../../../server/lib/utils'

describe '/db/prepaid', ->
  prepaidURL = getURL('/db/prepaid')
  prepaidCreateURL = getURL('/db/prepaid/-/create')

  headers = {'X-Change-Plan': 'true'}

  joeData = null
  stripe = require('stripe')(config.stripe.secretKey)
  joeCode = null

  verifyPrepaid = (user, prepaid, done) ->
    expect(prepaid.creator).toEqual(user.id)
    expect(prepaid.type).toEqual('subscription')
    expect(prepaid.maxRedeemers).toBeGreaterThan(0)
    expect(prepaid.code).toMatch(/^\w{8}$/)
    expect(prepaid.properties?.couponID).toEqual('free')
    done()

  it 'Clear database users and prepaids', (done) ->
    clearModels [User, Prepaid, Payment], (err) ->
      throw err if err
      done()

  it 'Anonymous creates prepaid code', (done) ->
    createPrepaid 'subscription', 1, 0, (err, res, body) ->
      expect(err).toBeNull()
      expect(res.statusCode).toBe(401)
      done()

  it 'Non-admin creates prepaid code', (done) ->
    loginNewUser (user1) ->
      expect(user1.isAdmin()).toEqual(false)
      createPrepaid 'subscription', 4, 0, (err, res, body) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe(403)
        done()

  it 'Admin creates prepaid code with type subscription', (done) ->
    loginNewUser (user1) ->
      user1.set('permissions', ['admin'])
      user1.save (err, user1) ->
        expect(err).toBeNull()
        expect(user1.isAdmin()).toEqual(true)
        createPrepaid 'subscription', 1, 0, (err, res, body) ->
          expect(err).toBeNull()
          expect(res.statusCode).toBe(200)
          verifyPrepaid user1, body, done

  it 'Admin creates prepaid code with type terminal_subscription', (done) ->
    loginNewUser (user1) ->
      user1.set('permissions', ['admin'])
      user1.save (err, user1) ->
        expect(err).toBeNull()
        expect(user1.isAdmin()).toEqual(true)
        createPrepaid 'terminal_subscription', 2, 3, (err, res, body) ->
          expect(err).toBeNull()
          expect(res.statusCode).toBe(200)
          expect(body.creator).toEqual(user1.id)
          expect(body.type).toEqual('terminal_subscription')
          expect(body.maxRedeemers).toEqual(2)
          expect(body.properties?.months).toEqual(3)
          expect(body.code).toMatch(/^\w{8}$/)
          done()


  it 'Admin creates prepaid code with invalid type', (done) ->
    loginNewUser (user1) ->
      user1.set('permissions', ['admin'])
      user1.save (err, user1) ->
        expect(err).toBeNull()
        expect(user1.isAdmin()).toEqual(true)
        createPrepaid 'bulldozer', 1, 0, (err, res, body) ->
          expect(err).toBeNull()
          expect(res.statusCode).toBe(403)
          done()

  it 'Admin creates prepaid code with no type specified', (done) ->
    loginNewUser (user1) ->
      user1.set('permissions', ['admin'])
      user1.save (err, user1) ->
        expect(err).toBeNull()
        expect(user1.isAdmin()).toEqual(true)
        createPrepaid null, 1, 0, (err, res, body) ->
          expect(err).toBeNull()
          expect(res.statusCode).toBe(403)
          done()

  it 'Admin creates prepaid code with invalid maxRedeemers', (done) ->
    loginNewUser (user1) ->
      user1.set('permissions', ['admin'])
      user1.save (err, user1) ->
        expect(err).toBeNull()
        expect(user1.isAdmin()).toEqual(true)
        createPrepaid 'subscription', 0, 0, (err, res, body) ->
          expect(err).toBeNull()
          expect(res.statusCode).toBe(403)
          done()

  it 'Non-admin requests /db/prepaid', (done) ->
    loginNewUser (user1) ->
      expect(user1.isAdmin()).toEqual(false)
      request.get {uri: prepaidURL}, (err, res, body) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe(403)
        done()

  it 'Admin requests /db/prepaid', (done) ->
    loginNewUser (user1) ->
      user1.set('permissions', ['admin'])
      user1.save (err, user1) ->
        expect(err).toBeNull()
        expect(user1.isAdmin()).toEqual(true)
        createPrepaid 'subscription', 1, 0, (err, res, prepaid) ->
          expect(err).toBeNull()
          expect(res.statusCode).toBe(200)
          request.get {uri: prepaidURL}, (err, res, body) ->
            expect(err).toBeNull()
            expect(res.statusCode).toBe(200)
            prepaids = JSON.parse(body)
            found = false
            for p in prepaids
              if p._id is prepaid._id
                found = true
                verifyPrepaid user1, p, done
                break
            expect(found).toEqual(true)
            done() unless found

  # *** Purchase Prepaid Codes *** #
  it 'Anonymous submits a prepaid purchase', (done) ->
    logoutUser () ->
      purchasePrepaid 'terminal_subscription', 3, 3, (err, res, prepaid) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe(401)
        done()

  it 'Should error if type isnt terminal_subscription', (done) ->
    loginNewUser (user1) ->
      purchasePrepaid 'subscription', 3, 3, (err, res, prepaid) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe(403)
        done()

  it 'Should error if maxRedeemers is invalid', (done) ->
    loginNewUser (user1) ->
      purchasePrepaid 'terminal_subscription', -1, 3, (err, res, prepaid) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe(403)
        done()
      purchasePrepaid 'terminal_subscription', 'foo', 3, (err, res, prepaid) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe(403)
        done()

  it 'Should error if months is invalid', (done) ->
    loginNewUser (user1) ->
      purchasePrepaid 'terminal_subscription', 3, -1, (err, res, prepaid) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe(403)
        done()
      purchasePrepaid 'terminal_subscription', 3, 'foo', (err, res, prepaid) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe(403)
        done()

  it 'Should error if maxRedeemers and months are less than 3', (done) ->
    loginNewUser (user1) ->
      purchasePrepaid 'terminal_subscription', 1, 1, (err, res, prepaid) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe(403)
        done()

  it 'User submits valid prepaid code purchase', (done) ->
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
        request.put {uri: getURL('/db/user'), json: joeData, headers: headers }, (err, res, body) ->
          joeData = body
          expect(res.statusCode).toBe(200)
          expect(joeData.stripe.customerID).toBeDefined()
          expect(firstSubscriptionID = joeData.stripe.subscriptionID).toBeDefined()
          expect(joeData.stripe.planID).toBe('basic')
          expect(joeData.stripe.token).toBeUndefined()
          purchasePrepaid 'terminal_subscription', 3, 3, (err, res, prepaid) ->
            expect(err).toBeNull()
            expect(res.statusCode).toBe(200)
            expect(prepaid.type).toEqual('terminal_subscription')
            expect(prepaid.code).toBeDefined()
            # Saving this code for later tests
            # TODO: don't make tests dependent on each other
            joeCode = prepaid.code
            expect(prepaid.creator).toBeDefined()
            expect(prepaid.maxRedeemers).toEqual(3)
            expect(prepaid.properties).toBeDefined()
            expect(prepaid.properties.months).toEqual(3)
            done()

  it 'Should have logged a Payment with the correct amount', (done) ->
    loginJoe (joe) ->
      query =
        purchaser: joe._id
      Payment.find query, (err, payments) ->
        expect(err).toBeNull()
        expect(payments).not.toBeNull()
        expect(payments.length).toEqual(1)
        expect(payments[0].get('amount')).toEqual(8991)
        done()


  it 'Anonymous cant redeem a prepaid code', (done) ->
    logoutUser () ->
      subscribeWithPrepaid joeCode, (err, res) ->
        expect(err).toBeNull()
        expect(res?.statusCode).toEqual(401)
        done()


  it 'User cant redeem a nonexistant prepaid code', (done) ->
    loginJoe (joe) ->
      subscribeWithPrepaid 'abc123', (err, res) ->
        expect(err).toBeNull()
        expect(res.statusCode).toEqual(403)
        done()

  it 'User cant redeem empty code', (done) ->
    loginJoe (joe) ->
      subscribeWithPrepaid '', (err, res) ->
        expect(err).toBeNull()
        expect(res.statusCode).toEqual(422)
        done()

  it 'Anonymous cant fetch a prepaid code', (done) ->
    expect(joeCode).not.toBeNull()
    logoutUser () ->
      fetchPrepaid joeCode, (err, res) ->
        expect(err).toBeNull()
        expect(res.statusCode).toEqual(403)
        done()

  it 'User can fetch a prepaid code', (done) ->
    expect(joeCode).not.toBeNull()
    loginJoe (joe) ->
      fetchPrepaid joeCode, (err, res, body) ->
        expect(err).toBeNull()
        expect(res.statusCode).toEqual(200)

        expect(body).toBeDefined()
        return done() unless body

        prepaid = JSON.parse(body)
        expect(prepaid.code).toEqual(joeCode)
        expect(prepaid.maxRedeemers).toEqual(3)
        expect(prepaid.properties?.months).toEqual(3)
        done()

  # TODO: Move redeem subscription prepaid code tests to subscription tests file

  it 'Creator can redeeem a prepaid code', (done) ->
    loginJoe (joe) ->
      expect(joeCode).not.toBeNull()
      expect(joeData.stripe?.customerID).toBeDefined()
      expect(joeData.stripe?.subscriptionID).toBeDefined()
      return done() unless joeData.stripe?.customerID

      # joe has a stripe subscription, so test if the months are added to the end of it.
      stripe.customers.retrieve joeData.stripe.customerID, (err, customer) =>
        expect(err).toBeNull()

        findStripeSubscription customer.id, subscriptionID: joeData.stripe?.subscriptionID, (subscription) =>
          if subscription
            stripeSubscriptionPeriodEndDate = new moment(subscription.current_period_end * 1000)
          else
            expect(stripeSubscriptionPeriodEndDate).toBeDefined()
            return done()

          subscribeWithPrepaid joeCode, (err, res, result) =>
            expect(err).toBeNull()
            expect(res.statusCode).toEqual(200)
            endDate = stripeSubscriptionPeriodEndDate.add(3, 'months').toISOString().substring(0, 10)
            expect(result?.stripe?.free).toEqual(endDate)
            expect(result?.purchased?.gems).toEqual(14000)
            findStripeSubscription customer.id, subscriptionID: joeData.stripe?.subscriptionID, (subscription) =>
              expect(subscription).toBeNull()
              done()

  it 'User can redeem a prepaid code', (done) ->
    loginSam (sam) ->
      subscribeWithPrepaid joeCode, (err, res, result) ->
        expect(err).toBeNull()
        expect(res.statusCode).toEqual(200)
        endDate = new moment().add(3, 'months').toISOString().substring(0, 10)
        expect(result?.stripe?.free).toEqual(endDate)
        expect(result?.purchased?.gems).toEqual(10500)
        done()

  it 'Wont allow the same person to redeem twice', (done) ->
    loginSam (sam) ->
      subscribeWithPrepaid joeCode, (err, res, result) ->
        expect(err).toBeNull()
        expect(res.statusCode).toEqual(403)
        done()

  it 'Will return redeemed code as part of codes list', (done) ->
    loginSam (sam) ->
      request.get "#{getURL('/db/user')}/#{sam.id}/prepaid_codes", (err, res) ->
        expect(err).toBeNull()
        expect(res.statusCode).toEqual(200)
        codes = JSON.parse res.body
        expect(codes.length).toEqual(1)
        done()

  it 'Third user can redeem a prepaid code', (done) ->
    loginNewUser (user) ->
      subscribeWithPrepaid joeCode, (err, res, result) ->
        expect(err).toBeNull()
        expect(res.statusCode).toEqual(200)
        endDate = new moment().add(3, 'months').toISOString().substring(0, 10)
        expect(result?.stripe?.free).toEqual(endDate)
        expect(result?.purchased?.gems).toEqual(10500)
        done()

  it 'Fourth user cannot redeem code', (done) ->
    loginNewUser (user) ->
      subscribeWithPrepaid joeCode, (err, res, result) ->
        expect(err).toBeNull()
        expect(res.statusCode).toEqual(403)
        done()


  it 'Can fetch a list of purchased and redeemed prepaid codes', (done) ->
    loginJoe (joe) ->
      purchasePrepaid 'terminal_subscription', 3, 1, (err, res, prepaid) ->
        request.get "#{getURL('/db/user')}/#{joe.id}/prepaid_codes", (err, res) ->
          expect(err).toBeNull()
          expect(res.statusCode).toEqual(200);
          codes = JSON.parse res.body
          expect(codes.length).toEqual(2)
          expect(codes[0].maxRedeemers).toEqual(3)
          expect(codes[0].properties).toBeDefined()
          expect(codes[0].properties.months).toEqual(3)
          done()

  it 'Test for injection', (done) ->
    loginNewUser (user) ->
      code = { $exists: true }
      subscribeWithPrepaid code, (err, res, result) ->
        expect(err).toBeNull()
        expect(res.statusCode).not.toEqual(200)
        done()
  # TODO: add a bunch of parallel tests trying to redeem a code with a high maxRedeemers (50?) to see what happens
