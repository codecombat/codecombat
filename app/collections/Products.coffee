CocoCollection = require './CocoCollection'
Product = require 'models/Product'
utils = require 'core/utils'

module.exports = class Products extends CocoCollection
  model: Product
  url: '/db/products'
  
  getByName: (name) -> @findWhere { name: name }

  getBasicSubscriptionForUser: (user) ->
    country = user?.get('stripe')?.couponID
    unless country
      country = user?.get('country')
    countrySpecificProduct = @findWhere { name: "#{country}_basic_subscription" }
    return countrySpecificProduct or @findWhere({ name: 'basic_subscription' })

  getLifetimeSubscriptionForUser: (user) ->
    country = user?.get('stripe')?.couponID
    unless country
      country = user?.get('country')
    countrySpecificProduct = @findWhere { name: "#{country}_lifetime_subscription" }
    return countrySpecificProduct or @findWhere({ name: 'lifetime_subscription' })
