require '../common'
config = require '../../../server_config'

describe '/db/prepaid', ->
  prepaidURL = getURL('/db/prepaid')
  prepaidCreateURL = getURL('/db/prepaid/-/create')

  headers = {'X-Change-Plan': 'true'}

  joeData = null
  stripe = require('stripe')(config.stripe.secretKey)


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
    createPrepaid 'subscription', 1, (err, res, body) ->
      expect(err).toBeNull()
      expect(res.statusCode).toBe(401)
      done()

  it 'Non-admin creates prepaid code', (done) ->
    loginNewUser (user1) ->
      expect(user1.isAdmin()).toEqual(false)
      createPrepaid 'subscription', 4, (err, res, body) ->
        expect(err).toBeNull()
        expect(res.statusCode).toBe(403)
        done()

  it 'Admin creates prepaid code with type subscription', (done) ->
    loginNewUser (user1) ->
      user1.set('permissions', ['admin'])
      user1.save (err, user1) ->
        expect(err).toBeNull()
        expect(user1.isAdmin()).toEqual(true)
        createPrepaid 'subscription', 1, (err, res, body) ->
          expect(err).toBeNull()
          expect(res.statusCode).toBe(200)
          verifyPrepaid user1, body, done

  it 'Admin creates prepaid code with invalid type', (done) ->
    loginNewUser (user1) ->
      user1.set('permissions', ['admin'])
      user1.save (err, user1) ->
        expect(err).toBeNull()
        expect(user1.isAdmin()).toEqual(true)
        createPrepaid 'bulldozer', 1, (err, res, body) ->
          expect(err).toBeNull()
          expect(res.statusCode).toBe(403)
          done()

  it 'Admin creates prepaid code with no type specified', (done) ->
    loginNewUser (user1) ->
      user1.set('permissions', ['admin'])
      user1.save (err, user1) ->
        expect(err).toBeNull()
        expect(user1.isAdmin()).toEqual(true)
        createPrepaid null, 1, (err, res, body) ->
          expect(err).toBeNull()
          expect(res.statusCode).toBe(403)
          done()

  it 'Admin creates prepaid code with invalid maxRedeemers', (done) ->
    loginNewUser (user1) ->
      user1.set('permissions', ['admin'])
      user1.save (err, user1) ->
        expect(err).toBeNull()
        expect(user1.isAdmin()).toEqual(true)
        createPrepaid 'subscription', 0, (err, res, body) ->
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
        createPrepaid 'subscription', 1, (err, res, prepaid) ->
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
          purchasePrepaid 'terminal_subscription', 3, 1, (err, res, prepaid) ->
            expect(err).toBeNull()
            expect(res.statusCode).toBe(200)
            expect(prepaid.type).toEqual('terminal_subscription')
            expect(prepaid.code).toBeDefined()
            expect(prepaid.creator).toBeDefined()
            expect(prepaid.maxRedeemers).toEqual(3)
            expect(prepaid.properties).toBeDefined()
            expect(prepaid.properties.months).toEqual(1)
            done()

  it 'Should have logged a Payment with the correct amount', (done) ->
    loginJoe (joe) ->
      query =
        purchaser: joe._id
      Payment.find query, (err, payments) ->
        expect(err).toBeNull()
        expect(payments).not.toBeNull()
        expect(payments.length).toEqual(1)
        expect(payments[0].get('amount')).toEqual(2997)
        done()

  # TODO: add a test to redeem a code, so it'll show up in the test below

  it 'can fetch a list of purchased and redeemed prepaid codes', (done) ->
    loginJoe (joe) ->
      purchasePrepaid 'terminal_subscription', 3, 1, (err, res, prepaid) ->
        request.get "#{getURL('/db/user')}/#{joe.id}/prepaid_codes", (err, res) ->
          expect(err).toBeNull()
          expect(res.statusCode).toEqual(200);
          codes = JSON.parse res.body
          expect(codes.length).toEqual(2)
          expect(codes[0].maxRedeemers).toEqual(3)
          expect(codes[0].properties).toBeDefined()
          expect(codes[0].properties.months).toEqual(1)
          done()

  it 'should refuse to return someone elses codes', (done) ->
    loginJoe (joe) ->
      request.get "#{getURL('/db/user')}/12345abc/prepaid_codes", (err, res) ->
          expect(err).toBeNull()
          expect(res.statusCode).toEqual(403)
          expect(res.body).toEqual('Forbidden')
          done()
