Product = require '../../models/Product'
errors = require '../../commons/errors'

module.exports.get = (req, res) ->
  
  Product.find().lean().exec (err, products) ->
    return errors.serverError(res) if err
    names = (product.name for product in products)
    for product in initProducts
      if not _.contains(names, product.name)
        # upsert products in initProducts if they DNE
        products.push(product)
        new Product(product).save _.noop
    res.send(products)
  
initProducts = [
  {
    name: 'gems_5'
    amount: 499
    gems: 5000
    priceString: '$4.99'
    i18n: 'buy_gems.few_gems'
  }

  {
    name: 'gems_10'
    amount: 999
    gems: 11000
    priceString: '$9.99'
    i18n: 'buy_gems.pile_gems'
  }

  {
    name: 'gems_20'
    amount: 1999
    gems: 25000
    priceString: '$19.99'
    i18n: 'buy_gems.chest_gems'
  }

  {
    name: 'custom'
    type: 'purchase'
  }

  {
    name: 'basic_subscription'
    amount: 999 # For calculating incremental quantity before sub creation
    gems: 3500
    planID: 'basic'
  }

  {
    name: 'year_subscription'
    amount: 9900
    gems: 42000
  }

  {
    name: 'prepaid_subscription'
    amount: 999
    gems: 3500
  }

  {
    name: 'course'
    amount: 400
  }
]