Product = require '../models/Product'
errors = require '../commons/errors'
config = require '../../server_config'
wrap = require 'co-express'
_ = require 'lodash'

get = wrap (req, res) ->
  products = yield Product.find().lean()
  unless _.size(products) or config.isProduction
    products = productStubs

  if req.features.china
    products = _.filter(products, (product) ->
      return true if product.name is 'lifetime_subscription'
      product.name.indexOf('subscription') is -1
    )
    return res.send(products)

  # Remove old unsupported subscription products
  products = _.filter products, (p) -> p.name not in ['year_subscription', 'lifetime_subscription2']
  products = _.filter(products, (p) -> p.i18nCoverage?) if req.query.view is 'i18n-coverage'

  for p in products
    if p.coupons?
      p.coupons = _.filter p.coupons, ((c) -> c.code is req.query.coupon)

  res.send(products)

###
Stub data, used in tests and dev environment.

These values are only upserted when the test/dev db does not already contain them.
If you are testing products and need to change them, you'll need to edit the db values directly.
###


productStubs = [
  {
    name: 'gems_5'
    amount: 100
    gems: 5000
    priceString: '$1.00'
    i18n: 'buy_gems.few_gems'
  }

  {
    name: 'gems_10'
    amount: 101
    gems: 11000
    priceString: '$1.01'
    i18n: 'buy_gems.pile_gems'
  }

  {
    name: 'gems_20'
    amount: 102
    gems: 25000
    priceString: '$1.02'
    i18n: 'buy_gems.chest_gems'
  }

  {
    name: 'custom'
    type: 'purchase'
  }

  {
    name: 'basic_subscription'
    amount: 100
    gems: 3500
    planID: 'basic'
    payPalBillingPlanID: 'P-23R58281B73475317X2K7B4A'
  }

  {
    name: 'year_subscription'
    amount: 1000
    gems: 42000
  }

  {
    name: 'prepaid_subscription'
    amount: 100
    gems: 3500
  }

  {
    name: 'course'
    amount: 100
  }

  {
    name: 'starter_license'
    amount: 100
  }

  {
    name: 'brazil_basic_subscription'
    amount: 0
    gems: 1500
    planID: 'basic'
    payPalBillingPlanID: 'P-2KP02511G2731913DX2K4IKA'
  }

  {
    name: 'lifetime_subscription'
    amount: 1000
    gems: 42000
    coupons: [{code: 'c1', amount: 10}, {code: 'c2', amount: 99}]
  }

  {
    name: 'lifetime_subscription2'
    amount: 2000
    gems: 42000
    coupons: [{code: 'c1', amount: 10}, {code: 'c2', amount: 99}]
  }

  {
    name: 'brazil_lifetime_subscription'
    amount: 1001
    gems: 42000
    coupons: [{code: 'c1', amount: 10}, {code: 'c2', amount: 99}]
  }
]

# For Backbone collection in dev environment, otherwise models merge
if not global.testing
  for productStub in productStubs
    productStub._id = _.uniqueId()

module.exports = {
  get
  productStubs
}
