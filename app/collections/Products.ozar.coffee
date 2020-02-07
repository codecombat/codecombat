CocoCollection = require './CocoCollection'
Product = require 'models/Product'
utils = require 'core/utils'

module.exports = class Products extends CocoCollection
  model: Product
  url: '/db/products'
  
  getByName: (name) -> @findWhere { name: name }

  getBasicSubscriptionForUser: (user) ->
    coupon = user?.get('stripe')?.couponID
    if coupon
      countrySpecificProduct = @findWhere { name: "#{coupon}_basic_subscription" }
    unless countrySpecificProduct
      countrySpecificProduct = @findWhere { name: "#{user?.get('country')}_basic_subscription" }
    return countrySpecificProduct or @findWhere({ name: 'basic_subscription' })

  getLifetimeSubscriptionForUser: (user) ->
    coupon = user?.get('stripe')?.couponID
    if coupon
      countrySpecificProduct = @findWhere { name: "#{coupon}_lifetime_subscription" }
    unless countrySpecificProduct
      countrySpecificProduct = @findWhere { name: "#{user?.get('country')}_lifetime_subscription" }
    return countrySpecificProduct or @findWhere({ name: 'lifetime_subscription' })
