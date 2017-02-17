subscriptions = require '../../../server/middleware/subscriptions'
utils = require '../utils'

describe 'checkForCoupon', ->
  beforeEach utils.wrap ->
    yield utils.populateProducts()
  
  it 'normally calls checkForExistingSubscription without a defined couponID', utils.wrap ->
    req = {}
    user = yield utils.initUser({country: 'united-states'})
    customer = {}
    spyOn(subscriptions, 'checkForExistingSubscription').and.returnValue(Promise.resolve())
    yield subscriptions.checkForCoupon(req, user, customer)
    args = subscriptions.checkForExistingSubscription.calls.argsFor(0)
    [req2, user2, customer2, couponID] = args
    expect(req2).toBe(req)
    expect(user2).toBe(user)
    expect(customer2).toBe(customer)
    expect(couponID).toBeUndefined()
    
  it 'adds country coupons if the user is from a country with a country-specific basic product', utils.wrap ->
    req = {}
    user = yield utils.initUser({country: 'brazil'})
    customer = {}
    spyOn(subscriptions, 'checkForExistingSubscription').and.returnValue(Promise.resolve())
    yield subscriptions.checkForCoupon(req, user, customer)
    args = subscriptions.checkForExistingSubscription.calls.argsFor(0)
    [req2, user2, customer2, couponID] = args
    expect(couponID).toBe('brazil')
