utils = require '../utils'
User = require '../../../server/models/User'
Payment = require '../../../server/models/Payment'
Product = require '../../../server/models/Product'
request = require '../request'
moment = require 'moment'
libUtils = require '../../../server/lib/utils'

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


  it 'allows purchase of a year subscription', utils.wrap ->
    @returnSuccessfulCharge()
    url = utils.getURL('/db/products/year_subscription/purchase')
    json = {stripe: { token: '1', timestamp: new Date() }}
    [res, body] = yield request.postAsync({url, json})
    expect(moment(res.body.stripe.free).isAfter(moment().add(1, 'year').subtract(1, 'day'))).toBe(true)
    expect(res.statusCode).toBe(200)

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

  it 'allows purchase of a lifetime subscription (2)', utils.wrap ->
    @returnSuccessfulCharge()
    url = utils.getURL('/db/products/lifetime_subscription2/purchase')
    json = {stripe: { token: '1', timestamp: new Date() }}
    [res, body] = yield request.postAsync({url, json})
    expect(res.body.stripe.free).toBe(true)
    expect(res.statusCode).toBe(200)
    product = yield Product.findOne({name:'lifetime_subscription2'})
    payment = yield Payment.findOne()
    expect(product.get('amount')).toBe(payment.get('amount'))

  it 'returns 402 when the charge is declined', utils.wrap ->
    @returnDeclinedCharge()
    url = utils.getURL('/db/products/lifetime_subscription/purchase')
    json = {stripe: { token: '1', timestamp: new Date() }}
    [res, body] = yield request.postAsync({url, json})
    expect(res.statusCode).toBe(402)
