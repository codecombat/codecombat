require '../common'
config = require '../../../server_config'
moment = require 'moment'
{findStripeSubscription} = require '../../../server/lib/utils'
async = require 'async'
nockUtils = require '../nock-utils'

describe '/db/prepaid', ->
  prepaidURL = getURL('/db/prepaid')
  prepaidCreateURL = getURL('/db/prepaid/-/create')

  headers = {'X-Change-Plan': 'true'}

  joeData = null
  stripe = require('stripe')(config.stripe.secretKey)
  joeCode = null

  verifyCoursePrepaid = (user, prepaid, done) ->
    expect(prepaid.creator).toEqual(user.id)
    expect(prepaid.type).toEqual('course')
    expect(prepaid.maxRedeemers).toBeGreaterThan(0)
    expect(prepaid.code).toMatch(/^\w{8}$/)
    done()

  verifySubscriptionPrepaid = (user, prepaid, done) ->
    expect(prepaid.creator).toEqual(user.id)
    expect(prepaid.type).toEqual('subscription')
    expect(prepaid.maxRedeemers).toBeGreaterThan(0)
    expect(prepaid.code).toMatch(/^\w{8}$/)
    expect(prepaid.properties?.couponID).toEqual('free')
    done()

  it 'Clear database', (done) ->
    clearModels [Course, CourseInstance, Payment, Prepaid, User], (err) ->
      throw err if err
      done()
      
  describe 'POST /db/prepaid/<id>/redeemers', ->

    it 'adds a given user to the redeemers property', (done) ->
      loginNewUser (user1) ->
        prepaid = new Prepaid({
          maxRedeemers: 1,
          redeemers: [],
          creator: user1.get('_id')
          code: 0
          type: 'course'
        })
        prepaid.save (err, prepaid) ->
          otherUser = new User()
          otherUser.save (err, otherUser) ->
            url = getURL("/db/prepaid/#{prepaid.id}/redeemers")
            redeemer = { userID: otherUser.id }
            request.post {uri: url, json: redeemer }, (err, res, body) ->
              expect(body.redeemers.length).toBe(1)
              expect(res.statusCode).toBe(200)
              prepaid = Prepaid.findById body._id, (err, prepaid) ->
                expect(err).toBeNull()
                expect(prepaid.get('redeemers').length).toBe(1)
                User.findById  otherUser.id, (err, user) ->
                  expect(user.get('coursePrepaidID').equals(prepaid.get('_id'))).toBe(true)
                  done()
              
    it 'does not allow more redeemers than maxRedeemers', (done) ->
      loginNewUser (user1) ->
        prepaid = new Prepaid({
          maxRedeemers: 0,
          redeemers: [],
          creator: user1.get('_id')
          code: 1
          type: 'course'
        })
        prepaid.save (err, prepaid) ->
          otherUser = new User()
          otherUser.save (err, otherUser) ->
            url = getURL("/db/prepaid/#{prepaid.id}/redeemers")
            redeemer = { userID: otherUser.id }
            request.post {uri: url, json: redeemer }, (err, res, body) ->
              expect(res.statusCode).toBe(403)
              done()

    it 'only allows the owner of the prepaid to add redeemers', (done) ->
      loginNewUser (user1) ->
        prepaid = new Prepaid({
          maxRedeemers: 1000,
          redeemers: [],
          creator: user1.get('_id')
          code: 2
          type: 'course'
        })
        prepaid.save (err, prepaid) ->
          loginNewUser (user2) ->
            otherUser = new User()
            otherUser.save (err, otherUser) ->
              url = getURL("/db/prepaid/#{prepaid.id}/redeemers")
              redeemer = { userID: otherUser.id }
              request.post {uri: url, json: redeemer }, (err, res, body) ->
                expect(res.statusCode).toBe(403)
                done()
            
    it 'is idempotent across prepaids collection', (done) ->
      loginNewUser (user1) ->
        otherUser = new User({
          'coursePrepaidID': new ObjectId()
        })
        otherUser.save (err, otherUser) ->
          prepaid1 = new Prepaid({
            redeemers: [{userID: otherUser.get('_id')}],
            code: 3
            type: 'course'
          })
          prepaid1.save (err, prepaid1) ->
            otherUser.set 'coursePrepaidID', prepaid1.id
            otherUser.save (err, otherUser) ->
              prepaid2 = new Prepaid({
                maxRedeemers: 10,
                redeemers: [],
                creator: user1.get('_id')
                code: 4
                type: 'course'
              })
              prepaid2.save (err, prepaid2) ->
                url = getURL("/db/prepaid/#{prepaid2.id}/redeemers")
                redeemer = { userID: otherUser.id }
                request.post {uri: url, json: redeemer }, (err, res, body) ->
                  expect(res.statusCode).toBe(200)
                  expect(body.redeemers.length).toBe(0)
                  done()

    it 'is idempotent to itself for a user other than the creator', (done) ->
      loginNewUser (user1) ->
        prepaid = new Prepaid({
          maxRedeemers: 2,
          redeemers: [],
          creator: user1.get('_id')
          code: 0
          type: 'course'
        })
        prepaid.save (err, prepaid) ->
          otherUser = new User()
          otherUser.save (err, otherUser) ->
            url = getURL("/db/prepaid/#{prepaid.id}/redeemers")
            redeemer = { userID: otherUser.id }
            request.post {uri: url, json: redeemer }, (err, res, body) ->
              expect(body.redeemers?.length).toBe(1)
              expect(res.statusCode).toBe(200)
              request.post {uri: url, json: redeemer }, (err, res, body) ->
                expect(body.redeemers?.length).toBe(1)
                expect(res.statusCode).toBe(200)
                prepaid = Prepaid.findById body._id, (err, prepaid) ->
                  expect(err).toBeNull()
                  expect(prepaid.get('redeemers').length).toBe(1)
                  User.findById  otherUser.id, (err, user) ->
                    expect(user.get('coursePrepaidID').equals(prepaid.get('_id'))).toBe(true)
                    done()

    it 'is idempotent to itself for the creator', (done) ->
      loginNewUser (user1) ->
        prepaid = new Prepaid({
          maxRedeemers: 2,
          redeemers: [],
          creator: user1.get('_id')
          code: 0
          type: 'course'
        })
        prepaid.save (err, prepaid) ->
          otherUser = new User()
          otherUser.save (err, otherUser) ->
            url = getURL("/db/prepaid/#{prepaid.id}/redeemers")
            redeemer = { userID: user1.id }
            request.post {uri: url, json: redeemer }, (err, res, body) ->
              expect(body.redeemers?.length).toBe(1)
              expect(res.statusCode).toBe(200)
              request.post {uri: url, json: redeemer }, (err, res, body) ->
                expect(body.redeemers?.length).toBe(1)
                expect(res.statusCode).toBe(200)
                prepaid = Prepaid.findById body._id, (err, prepaid) ->
                  expect(err).toBeNull()
                  expect(prepaid.get('redeemers').length).toBe(1)
                  User.findById  user1.id, (err, user) ->
                    expect(user.get('coursePrepaidID').equals(prepaid.get('_id'))).toBe(true)
                    redeemer = { userID: otherUser.id }
                    request.post {uri: url, json: redeemer }, (err, res, body) ->
                      expect(body.redeemers?.length).toBe(2)
                      expect(res.statusCode).toBe(200)
                      done()

    it 'return terminal prepaids', (done) ->
      endDate = new Date()
      endDate.setUTCMonth(endDate.getUTCMonth() + 2)
      loginNewUser (user1) ->
        prepaid = new Prepaid({
          maxRedeemers: 500,
          redeemers: [],
          creator: user1.get('_id')
          type: 'course'
          properties:
            endDate: endDate
        })
        prepaid.save (err, prepaid) ->
          expect(err).toBeNull()
          url = getURL("/db/prepaid?creator=#{user1.id}")
          request.get {uri: url}, (err, res, body) ->
            expect(res.statusCode).toBe(200)
            documents = JSON.parse(body)
            expect(documents.length).toEqual(1)
            return done() unless documents.length is 1
            expect(documents[0]?.properties?.endDate).toEqual(endDate.toISOString())
            done()

    it 'do not return expired terminal prepaids', (done) ->
      endDate = new Date()
      endDate.setUTCMonth(endDate.getUTCMonth() - 1)
      loginNewUser (user1) ->
        prepaid = new Prepaid({
          maxRedeemers: 500,
          redeemers: [],
          creator: user1.get('_id')
          type: 'course'
          properties:
            endDate: endDate
        })
        prepaid.save (err, prepaid) ->
          expect(err).toBeNull()
          url = getURL("/db/prepaid?creator=#{user1.id}")
          request.get {uri: url}, (err, res, body) ->
            expect(res.statusCode).toBe(200)
            documents = JSON.parse(body)
            expect(documents.length).toEqual(0)
            done()

    it 'redeem terminal prepaids', (done) ->
      endDate = new Date()
      endDate.setUTCMonth(endDate.getUTCMonth() + 2)
      loginNewUser (user1) ->
        prepaid = new Prepaid({
          maxRedeemers: 500,
          redeemers: [],
          creator: user1.get('_id')
          type: 'course'
          properties:
            endDate: endDate
        })
        prepaid.save (err, prepaid) ->
          expect(err).toBeNull()
          otherUser = new User()
          otherUser.save (err, otherUser) ->
            url = getURL("/db/prepaid/#{prepaid.id}/redeemers")
            redeemer = { userID: otherUser.id }
            request.post {uri: url, json: redeemer }, (err, res, body) ->
              expect(body.redeemers?.length).toBe(1)
              expect(res.statusCode).toBe(200)
              return done() unless res.statusCode is 200
              prepaid = Prepaid.findById body._id, (err, prepaid) ->
                expect(err).toBeNull()
                expect(prepaid.get('redeemers').length).toBe(1)
                User.findById  otherUser.id, (err, user) ->
                  expect(user.get('coursePrepaidID').equals(prepaid.get('_id'))).toBe(true)
                  done()

    it 'do not redeem expired terminal prepaids', (done) ->
      endDate = new Date()
      endDate.setUTCMonth(endDate.getUTCMonth() - 1)
      loginNewUser (user1) ->
        prepaid = new Prepaid({
          maxRedeemers: 500,
          redeemers: [],
          creator: user1.get('_id')
          type: 'course'
          properties:
            endDate: endDate
        })
        prepaid.save (err, prepaid) ->
          expect(err).toBeNull()
          otherUser = new User()
          otherUser.save (err, otherUser) ->
            url = getURL("/db/prepaid/#{prepaid.id}/redeemers")
            redeemer = { userID: otherUser.id }
            request.post {uri: url, json: redeemer }, (err, res, body) ->
              expect(res.statusCode).toBe(403)
              done()
                      
  it 'Clear database', (done) ->
    clearModels [Course, CourseInstance, Payment, Prepaid, User], (err) ->
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
          verifySubscriptionPrepaid user1, body, done

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
                verifySubscriptionPrepaid user1, p, done
                break
            expect(found).toEqual(true)
            done() unless found

  describe 'Purchase course', ->
    afterEach nockUtils.teardownNock
    
    it 'Standard user purchases a prepaid for 0 seats', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-course-test-1.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            purchasePrepaid 'course', {}, 0, token.id, (err, res, prepaid) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(422)
              nockDone()
              done()
            
    it 'Standard user purchases a prepaid for 1 seat', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-course-test-2.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            purchasePrepaid 'course', {}, 1, token.id, (err, res, prepaid) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(200)
              verifyCoursePrepaid user1, prepaid, ->
                nockDone()
                done()

    it 'Standard user purchases a prepaid for 3 seats', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-course-test-3.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            purchasePrepaid 'course', {}, 3, token.id, (err, res, prepaid) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(200)
              verifyCoursePrepaid user1, prepaid, ->
                nockDone()
                done()
            
  describe 'Purchase terminal_subscription', ->
    afterEach nockUtils.teardownNock
    
    it 'Anonymous submits a prepaid purchase', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-term-sub-test-1.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          logoutUser () ->
            purchasePrepaid 'terminal_subscription', months: 3, 3, token.id, (err, res, prepaid) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(401)
              nockDone()
              done()

    it 'Should error if type isnt terminal_subscription', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-term-sub-test-2.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            purchasePrepaid 'subscription', months: 3, 3, token.id, (err, res, prepaid) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(403)
              nockDone()
              done()

    it 'Should error if maxRedeemers is -1', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-term-sub-test-3.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            purchasePrepaid 'terminal_subscription', months: 3, -1, token.id, (err, res, prepaid) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(422)
              nockDone()
              done()

    it 'Should error if maxRedeemers is foo', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-term-sub-test-4.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            purchasePrepaid 'terminal_subscription', months: 3, 'foo', token.id, (err, res, prepaid) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(422)
              nockDone()
              done()

    it 'Should error if months is -1', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-term-sub-test-5.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            purchasePrepaid 'terminal_subscription', months: -1, 3, token.id, (err, res, prepaid) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(422)
              nockDone()
              done()

    it 'Should error if months is foo', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-term-sub-test-6.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            purchasePrepaid 'terminal_subscription', months: 'foo', 3, token.id, (err, res, prepaid) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(422)
              nockDone()
              done()

    it 'Should error if maxRedeemers and months are less than 3', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-term-sub-test-7.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user1) ->
            purchasePrepaid 'terminal_subscription', months: 1, 1, token.id, (err, res, prepaid) ->
              expect(err).toBeNull()
              expect(res.statusCode).toBe(403)
              nockDone()
              done()

    it 'User submits valid prepaid code purchase', (done) ->
      nockUtils.setupNock 'db-prepaid-purchase-term-sub-test-8.json', (err, nockDone) ->
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
              # TODO: is this test still valid after new token?
              stripe.tokens.create {
                card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
              }, (err, token) ->
                purchasePrepaid 'terminal_subscription', months: 3, 3, token.id, (err, res, prepaid) ->
                  expect(err).toBeNull()
                  expect(res.statusCode).toBe(200)
                  expect(prepaid.type).toEqual('terminal_subscription')
                  expect(prepaid.code).toBeDefined()
                  # Saving this code for later tests
                  # TODO: don't make tests dependent on each other
                  joeCode = prepaid.code
                  expect(prepaid.creator).toBeDefined()
                  expect(prepaid.maxRedeemers).toEqual(3)
                  expect(prepaid.exhausted).toBe(false)
                  expect(prepaid.properties).toBeDefined()
                  expect(prepaid.properties.months).toEqual(3)
                  nockDone()
                  done()

    it 'Should have logged a Payment with the correct amount', (done) ->
      loginJoe (joe) ->
        query =
          purchaser: joe._id
        Payment.find query, (err, payments) ->
          expect(err).toBeNull()
          expect(payments).not.toBeNull()
          expect(payments.length).toEqual(1)
          expect(payments[0].get('amount')).toEqual(900)
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
          expect(res.statusCode).toEqual(404)
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
  describe 'Subscription redeem tests', ->
    afterEach nockUtils.teardownNock
    
    it 'Creator can redeeem a prepaid code', (done) ->
      nockUtils.setupNock 'db-sub-redeem-test-1.json', (err, nockDone) ->
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
                  nockDone()
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
      nockUtils.setupNock 'db-sub-redeem-test-2.json', (err, nockDone) ->
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user) ->
            purchasePrepaid 'terminal_subscription', months: 1, 3, token.id, (err, res, prepaid) ->
              request.get "#{getURL('/db/user')}/#{user.id}/prepaid_codes", (err, res) ->
                expect(err).toBeNull()
                expect(res.statusCode).toEqual(200);
                codes = JSON.parse res.body
                expect(codes.length).toEqual(1)
                expect(codes[0].maxRedeemers).toEqual(3)
                expect(codes[0].properties).toBeDefined()
                expect(codes[0].properties.months).toEqual(1)
                nockDone()
                done()

    it 'Test for injection', (done) ->
      loginNewUser (user) ->
        code = { $exists: true }
        subscribeWithPrepaid code, (err, res, result) ->
          expect(err).toBeNull()
          expect(res.statusCode).not.toEqual(200)
          done()

    it 'Test a bunch of people trying to redeem at once', (done) ->
      nockUtils.setupNock 'db-sub-redeem-test-3.json', (err, nockDone) ->
        doRedeem = (userX, code, testnum, retry, fnDone) =>
          loginUser userX, () =>
            endDate = new moment().add(3, 'months').toISOString().substring(0, 10)
            subscribeWithPrepaid code, (err, res, result) ->
              if err
                return fnDone(err)
  
              expect(err).toBeNull()
              expect(result).toBeDefined()
              if result.stripe
                expect(result.stripe).toBeDefined()
                expect(result.stripe.free).toEqual(endDate)
                expect(result?.purchased?.gems).toEqual(10500)
                return fnDone(null, {status: "ok", msg: "Redeemed " + retry})
              else
                return fnDone(null, {status: 'error', msg: "Redeem attempt Error #{result} (#{userX.id})" + retry })
  
        redeemPrepaidFn = (code, testnum) =>
          (fnDone) =>
            loginNewUser (user1) =>
              doRedeem(user1, code, testnum, 0, fnDone)
  
        stripe.tokens.create {
          card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
        }, (err, token) ->
          loginNewUser (user) =>
            codeRedeemers = 50
            codeMonths = 3
            redeemers = 51
            purchasePrepaid 'terminal_subscription', months: codeMonths, codeRedeemers, token.id, (err, res, prepaid) ->
              expect(err).toBeNull()
              expect(prepaid).toBeDefined()
              expect(prepaid.code).toBeDefined()
              tasks = (redeemPrepaidFn(prepaid.code, i) for i in [0...redeemers])
              async.parallel tasks, (err, results) =>
                redeemed = 0
                error = 0
                for result in results
                  redeemed += 1 if result.status is 'ok'
                  error += 1 if result.status is 'error'
                expect(redeemed).toEqual(codeRedeemers)
                expect(error).toEqual(redeemers - codeRedeemers)
                nockDone()
                done()
