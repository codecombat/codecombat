Product = require '../../models/Product'
errors = require '../../commons/errors'
config = require '../../../server_config'
wrap = require 'co-express'

get = wrap (req, res) ->
  products = yield Product.find()
  return res.send(productStubs) unless _.size(products) or config.isProduction
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
  }

  {
    name: 'year_subscription'
    amount: 1000
    gems: 42000
  }

  {
    name: 'year_subscription_b'
    amount: 1001
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
  }
]

module.exports = {
  get
  productStubs
}
