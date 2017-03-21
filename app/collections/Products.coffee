CocoCollection = require './CocoCollection'
Product = require 'models/Product'

module.exports = class Products extends CocoCollection
  model: Product
  url: '/db/products'
  
  getByName: (name) -> @findWhere { name: name }

  getBasicSubscriptionForUser: (user) ->
    if countrySpecificProduct = @findWhere { name: "#{user?.get('country')}_basic_subscription" }
      return countrySpecificProduct
    else
      return @findWhere { name: 'basic_subscription' }
