utils = require '../utils'
User = require '../../../server/models/User'
Payment = require '../../../server/models/Payment'
Product = require '../../../server/models/Product'
request = require '../request'
moment = require 'moment'
libUtils = require '../../../server/lib/utils'

describe 'GET /db/products', ->
  beforeEach utils.wrap ->
    # TODO: Clear Products, to make this test not dependent on dev db
    #       Also, make other tests not break when you do that.
    yield utils.clearModels([User, Payment])
    yield utils.populateProducts()
    @user = yield utils.initUser()
    yield utils.loginUser(@user)

  it 'shouldnt leak coupon code information', utils.wrap ->
      url = utils.getURL('/db/products/')
      [res, doc] = yield request.getAsync({url, json: true})
      ls2 = _.find doc, ((x) -> /^lifetime_subscription$/.test x.name)
      expect(ls2.coupons).toEqual([])

  it 'should accept the coupon code QS', utils.wrap ->
      url = utils.getURL('/db/products/')
      [res, doc] = yield request.getAsync(url: url + '?coupon=c1', json: true)
      ls2 = _.find doc, ((x) -> /^lifetime/.test x.name)
      expect(ls2.coupons[0].amount).toBe(10)
      expect(ls2.coupons.length).toBe(1)

describe 'POST /db/products/:handle/purchase', ->

  beforeEach utils.wrap ->
    yield utils.clearModels([User, Payment])
    yield utils.populateProducts()
    @user = yield utils.initUser()
    yield utils.loginUser(@user)
    spyOn(stripe.customers, 'create').and.callFake (newCustomer, cb) -> cb(null, {id: 'cus_1'})
    spyOn(libUtils, 'findStripeSubscriptionAsync').and.returnValue(Promise.resolve(null))
    @returnSuccessfulCharge = ->
      spyOn(stripe.charges, 'create').and.callFake (opts, cb) ->
        cb(null, _.assign({id: 'charge_1'}, _.pick(opts, 'metadata', 'amount', 'customer')))
    @returnDeclinedCharge = ->
      spyOn(stripe.charges, 'create').and.callFake (opts, cb) ->
        cb(new Error('Your card was declined'))


  it 'disallows purchase of a year subscription', utils.wrap ->
    @returnSuccessfulCharge()
    url = utils.getURL('/db/products/year_subscription/purchase')
    json = {stripe: { token: '1', timestamp: new Date() }}
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(422)

  it 'allows purchase of a lifetime subscription', utils.wrap ->
    @returnSuccessfulCharge()
    url = utils.getURL('/db/products/lifetime_subscription/purchase')
    json = {stripe: { token: '1', timestamp: new Date() }}
    [res, body] = yield request.postAsync({url, json})
    expect(res.body.stripe.free).toBe(true)
    expect(res.statusCode).toBe(200)
    product = yield Product.findOne({name:'lifetime_subscription'})
    payment = yield Payment.findOne()
    expect(product.get('amount')).toBe(payment.get('amount'))

  it 'disallows purchase of a lifetime subscription (2)', utils.wrap ->
    @returnSuccessfulCharge()
    url = utils.getURL('/db/products/lifetime_subscription2/purchase')
    json = {stripe: { token: '1', timestamp: new Date() }}
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(422)

  it 'allows purchase of a lifetime subscription with coupon', utils.wrap ->
    @returnSuccessfulCharge()
    url = utils.getURL('/db/products/lifetime_subscription/purchase')
    json = {stripe: { token: '1', timestamp: new Date() }, coupon: 'c1'}
    [res, body] = yield request.postAsync({url, json})
    expect(res.body.stripe.free).toBe(true)
    expect(res.statusCode).toBe(200)
    product = yield Product.findOne({name:'lifetime_subscription'})
    payment = yield Payment.findOne()
    expect(product.get('coupons')[0].amount).toBe(payment.get('amount'))
    metadata = stripe.charges.create.calls.argsFor(0)[0].metadata
    expect(metadata.couponCode).toBe('c1')

  it 'blocks purchase of a lifetime subscription with an invalid coupon', utils.wrap ->
    @returnSuccessfulCharge()
    url = utils.getURL('/db/products/lifetime_subscription/purchase')
    json = {stripe: { token: '1', timestamp: new Date() }, coupon: 'x1'}
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(404)

  it 'returns 402 when the charge is declined', utils.wrap ->
    @returnDeclinedCharge()
    url = utils.getURL('/db/products/lifetime_subscription/purchase')
    json = {stripe: { token: '1', timestamp: new Date() }}
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(402)
