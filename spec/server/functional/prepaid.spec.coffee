require '../common'
config = require '../../../server_config'
moment = require 'moment'
{findStripeSubscription} = require '../../../server/lib/utils'
async = require 'async'
nockUtils = require '../nock-utils'
utils = require '../utils'
Promise = require 'bluebird'
Payment = require '../../../server/models/Payment'
Prepaid = require '../../../server/models/Prepaid'
User = require '../../../server/models/User'
Course = require '../../../server/models/Course'
CourseInstance = require '../../../server/models/CourseInstance'
request = require '../request'

describe 'POST /db/prepaid', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([User, Prepaid])
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    done()
  
  it 'creates a new prepaid for type "course"', utils.wrap (done) ->
    user = yield utils.initUser()
    [res, body] = yield request.postAsync({url: getURL('/db/prepaid'), json: {
      type: 'course'
      creator: user.id
    }})
    expect(res.statusCode).toBe(201)
    prepaid = yield Prepaid.findById(res.body._id)
    expect(prepaid).toBeDefined()
    expect(prepaid.get('creator').equals(user._id)).toBe(true)
    expect(prepaid.get('code')).toBeDefined()
    done()
    
  it 'does not work for non-admins', utils.wrap (done) ->
    user = yield utils.initUser()
    yield utils.loginUser(user)
    [res, body] = yield request.postAsync({url: getURL('/db/prepaid'), json: {
      type: 'course'
      creator: user.id
    }})
    expect(res.statusCode).toBe(403)
    done()
    
  it 'accepts start and end dates', utils.wrap (done) ->
    user = yield utils.initUser()
    [res, body] = yield request.postAsync({url: getURL('/db/prepaid'), json: {
      type: 'course'
      creator: user.id
      startDate: new Date().toISOString(2001,1,1)
      endDate: new Date().toISOString(2010,1,1)
    }})
    expect(res.statusCode).toBe(201)
    prepaid = yield Prepaid.findById(res.body._id)
    expect(prepaid).toBeDefined()
    expect(prepaid.get('startDate')).toBeDefined()
    expect(prepaid.get('endDate')).toBeDefined()
    done()
    
    
describe 'GET /db/prepaid/:handle', ->
  it 'populates startDate and endDate with default values', utils.wrap (done) ->
    prepaid = new Prepaid({type: 'course' })
    yield prepaid.save()
    [res, body] = yield request.getAsync({url: getURL("/db/prepaid/#{prepaid.id}"), json: true})
    expect(body.endDate).toBe(Prepaid.DEFAULT_END_DATE)
    expect(body.startDate).toBe(Prepaid.DEFAULT_START_DATE)
    done()
  

describe 'POST /db/prepaid/:handle/redeemers', ->
  
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Course, CourseInstance, Payment, Prepaid, User])
    @teacher = yield utils.initUser({role: 'teacher'})
    @admin = yield utils.initAdmin()
    yield utils.loginUser(@admin)
    @prepaid = yield utils.makePrepaid({ creator: @teacher.id })
    yield utils.loginUser(@teacher)
    @student = yield utils.initUser()
    @url = getURL("/db/prepaid/#{@prepaid.id}/redeemers")
    done()

  it 'adds a given user to the redeemers property', utils.wrap (done) ->
    [res, body] = yield request.postAsync {uri: @url, json: { userID: @student.id } }
    expect(body.redeemers.length).toBe(1)
    expect(res.statusCode).toBe(201)
    prepaid = yield Prepaid.findById(body._id)
    expect(prepaid.get('redeemers').length).toBe(1)
    @student = yield User.findById(@student.id)
    expect(@student.get('coursePrepaid')._id.equals(@prepaid._id)).toBe(true)
    expect(@student.get('role')).toBe('student')
    done()

  it 'returns 403 if maxRedeemers is reached', utils.wrap (done) ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    prepaid = yield utils.makePrepaid({ creator: @teacher.id, maxRedeemers: 0 })
    url = getURL("/db/prepaid/#{prepaid.id}/redeemers")
    yield utils.loginUser(@teacher)
    [res, body] = yield request.postAsync({uri: url, json: { userID: @student.id } })
    expect(res.statusCode).toBe(403)
    expect(res.body.message).toBe('This prepaid is exhausted')
    done()

  it 'returns 403 unless the user is the "creator"', utils.wrap (done) ->
    @otherTeacher = yield utils.initUser({role: 'teacher'})
    yield utils.loginUser(@otherTeacher)
    [res, body] = yield request.postAsync({uri: @url, json: { userID: @student.id } })
    expect(res.statusCode).toBe(403)
    expect(res.body.message).toBe('You may not redeem licenses from this prepaid')
    done()

  it 'returns 403 if the prepaid is expired', utils.wrap (done) ->
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    prepaid = yield utils.makePrepaid({ creator: @teacher.id, endDate: moment().subtract(1, 'month').toISOString() })
    url = getURL("/db/prepaid/#{prepaid.id}/redeemers")
    yield utils.loginUser(@teacher)
    [res, body] = yield request.postAsync({uri: url, json: { userID: @student.id } })
    expect(res.statusCode).toBe(403)
    expect(res.body.message).toBe('This prepaid is expired')
    done()

  it 'is idempotent across prepaids collection', utils.wrap (done) ->
    student = yield utils.initUser({ coursePrepaid: { _id: new Prepaid()._id } })
    [res, body] = yield request.postAsync({uri: @url, json: { userID: student.id } })
    expect(res.statusCode).toBe(200)
    expect(body.redeemers.length).toBe(0)
    done()

  it 'is idempotent to itself', utils.wrap (done) ->
    [res, body] = yield request.postAsync({uri: @url, json: { userID: @student.id } })
    expect(body.redeemers?.length).toBe(1)
    expect(res.statusCode).toBe(201)
    [res, body] = yield request.postAsync({uri: @url, json: { userID: @student.id } })
    expect(body.redeemers?.length).toBe(1)
    expect(res.statusCode).toBe(200)
    prepaid = yield Prepaid.findById(body._id)
    expect(prepaid.get('redeemers').length).toBe(1)
    student = yield User.findById(@student.id)
    expect(student.get('coursePrepaid')._id.equals(@prepaid._id)).toBe(true)
    done()
    
  it 'updates the user if their license is expired', utils.wrap (done) ->
    yield utils.loginUser(@admin)
    prepaid = yield utils.makePrepaid({
      creator: @teacher.id
      startDate: moment().subtract(2, 'month').toISOString()
      endDate: moment().subtract(1, 'month').toISOString()
    })
    @student.set('coursePrepaid', _.pick(prepaid.toObject(), '_id', 'startDate', 'endDate'))
    yield @student.save()
    yield utils.loginUser(@teacher)
    [res, body] = yield request.postAsync {uri: @url, json: { userID: @student.id } }
    expect(body.redeemers.length).toBe(1)
    expect(res.statusCode).toBe(201)
    student = yield User.findById(@student.id)
    expect(student.get('coursePrepaid')._id.equals(@prepaid._id)).toBe(true)
    done()


describe 'GET /db/prepaid?creator=:id', ->
  beforeEach utils.wrap (done) ->
    yield utils.clearModels([Course, CourseInstance, Payment, Prepaid, User])
    @teacher = yield utils.initUser({role: 'teacher'})
    admin = yield utils.initAdmin()
    yield utils.loginUser(admin)
    @prepaid = yield utils.makePrepaid({ creator: @teacher.id })
    @otherPrepaid = yield utils.makePrepaid({ creator: admin.id })
    @expiredPrepaid = yield utils.makePrepaid({ creator: @teacher.id, endDate: moment().subtract(1, 'month').toISOString() })
    @unmigratedPrepaid = yield utils.makePrepaid({ creator: @teacher.id })
    yield @unmigratedPrepaid.update({$unset: { endDate: '', startDate: '' }})
    yield utils.loginUser(@teacher)
    done()
    
  it 'return all prepaids for the creator', utils.wrap (done) ->
    url = getURL("/db/prepaid?creator=#{@teacher.id}")
    [res, body] = yield request.getAsync({uri: url, json: true})
    expect(res.statusCode).toBe(200)
    expect(res.body.length).toEqual(3)
    if _.any((prepaid._id is @otherPrepaid.id for prepaid in res.body))
      fail('Found the admin prepaid in response')
    for prepaid in res.body
      unless prepaid.startDate and prepaid.endDate
        fail('All prepaids should have start and end dates')
    expect(res.body[0]._id).toBe(@prepaid.id)
    done()
    
  it 'returns 403 if the user tries to view another user\'s prepaids', utils.wrap (done) ->
    anotherUser = yield utils.initUser()
    url = getURL("/db/prepaid?creator=#{anotherUser.id}")
    [res, body] = yield request.getAsync({uri: url, json: true})
    expect(res.statusCode).toBe(403)
    done()

    
describe '/db/prepaid', ->
  prepaidURL = getURL('/db/prepaid')

  headers = {'X-Change-Plan': 'true'}

  joeData = null
  stripe = require('stripe')(config.stripe.secretKey)
  joeCode = null

  verifyCoursePrepaid = (user, prepaid, done) ->
    expect(prepaid.creator).toEqual(user.id)
    expect(prepaid.type).toEqual('course')
    expect(prepaid.maxRedeemers).toBeGreaterThan(0)
    expect(prepaid.code).toMatch(/^\w{8}$/)
    return done() if user.isAdmin()
    Payment.findOne {prepaidID: new ObjectId(prepaid._id)}, (err, payment) ->
      expect(err).toBeNull()
      expect(payment).not.toBeNull()
      expect(payment?.get('purchaser')).toEqual(user._id)
      done()

  verifySubscriptionPrepaid = (user, prepaid, done) ->
    expect(prepaid.creator).toEqual(user.id)
    expect(prepaid.type).toEqual('subscription')
    expect(prepaid.maxRedeemers).toBeGreaterThan(0)
    expect(prepaid.code).toMatch(/^\w{8}$/)
    expect(prepaid.properties?.couponID).toEqual('free')
    return done() if user.isAdmin()
    Payment.findOne {prepaidID: new ObjectId(prepaid._id)}, (err, payment) ->
      expect(err).toBeNull()
      expect(payment).not.toBeNull()
      expect(payment?.get('purchaser')).toEqual(user._id)
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

    it 'enforces the maximum number of redeemers in a race condition', utils.wrap (done) ->
      nockDone = yield nockUtils.setupNockAsync 'db-sub-redeem-test-3.json'
      stripe.tokens.createAsync = Promise.promisify(stripe.tokens.create, {context: stripe.tokens})
      token = yield stripe.tokens.createAsync({
        card: { number: '4242424242424242', exp_month: 12, exp_year: 2020, cvc: '123' }
      })

      user = yield utils.initUser()
      yield utils.loginUser(user)
      
      codeRedeemers = 50
      codeMonths = 3
      redeemers = 51
      
      purchasePrepaidAsync = Promise.promisify(purchasePrepaid, {multiArgs: true})
      [res, prepaid] = yield purchasePrepaidAsync('terminal_subscription', months: codeMonths, codeRedeemers, token.id)
      
      expect(prepaid).toBeDefined()
      expect(prepaid.code).toBeDefined()

      # Make 'threads', which are objects that encapsulate each user and their cookies
      threads = []
      for index in [0...redeemers]
        thread = {}
        thread.request = request.defaults({jar: request.jar()})
        thread.request.postAsync = Promise.promisify(thread.request.post, { context: thread.request })
        thread.user = yield utils.initUser()
        yield utils.loginUser(thread.user, {request: thread.request})
        threads.push(thread)
    
      # Spawn all requests at once!
      requests = []
      options = {
        url: getURL('/db/subscription/-/subscribe_prepaid')
        json: { ppc: prepaid.code }
      }
      for thread in threads
        requests.push(thread.request.postAsync(options))
        
      # Wait until all requests finish, make sure all but one succeeded
      responses = yield requests
      redeemed = _.size(_.where(responses, {statusCode: 200}))
      errors = _.size(_.where(responses, {statusCode: 403}))
      expect(redeemed).toEqual(codeRedeemers)
      expect(errors).toEqual(redeemers - codeRedeemers)
      nockDone()
      done()
