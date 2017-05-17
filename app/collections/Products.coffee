CocoCollection = require './CocoCollection'
Product = require 'models/Product'
utils = require 'core/utils'

module.exports = class Products extends CocoCollection
  model: Product
  url: () ->
    if utils.getQueryVariable('coupon')
      "/db/products?coupon=#{utils.getQueryVariable('coupon')}"
    else
      '/db/products'
  
  getByName: (name) -> @findWhere { name: name }

  getBasicSubscriptionForUser: (user) ->
    if countrySpecificProduct = @findWhere { name: "#{user?.get('country')}_basic_subscription" }
      return countrySpecificProduct
    else
      return @findWhere { name: 'basic_subscription' }
