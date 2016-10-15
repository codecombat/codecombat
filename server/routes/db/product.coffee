Product = require '../../models/Product'
errors = require '../../commons/errors'
config = require '../../../server_config'
wrap = require 'co-express'

get = wrap (req, res) ->
  products = yield Product.find()
  unless _.size(products) or config.isProduction
    products = productStubs.map (product) -> new Product(product)
  productGroups = {}
  for product in products
    productGroups[product.get('name')] ?= []
    productGroups[product.get('name')].push(product)
  finalProducts = []
  for name, productGroup of productGroups
    if productGroup.length > 1
      # TODO: Use real seeded randomness
      numTestGroups = productGroup.length
      testGroupNumber = parseInt(req.user.id.slice(10), 16) % numTestGroups
      selectedProduct = productGroup.find (product) ->
        product.get('test_group').toString() is testGroupNumber.toString()
    else
      selectedProduct = productGroup[0]
    # TODO: Strip the 'test_group' attribute from the product? Eh, we probably don't care.
    finalProducts.push(selectedProduct)
  res.send(finalProducts)

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
    test_group: '0'
  }
  {
    name: 'year_subscription'
    amount: 1200
    gems: 50400
    test_group: '1'
  }
  {
    name: 'year_subscription'
    amount: 800
    gems: 33600
    test_group: '2'
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
