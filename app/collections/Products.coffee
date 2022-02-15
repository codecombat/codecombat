CocoCollection = require './CocoCollection'
Product = require 'models/Product'
utils = require 'core/utils'

# This collection is also used by the Vuex products module, ideally we would
# transfer the logic in this collection to the Vuex module but we're not doing
# active work on this product so leaving as is for now.
module.exports = class Products extends CocoCollection
  model: Product
  url: '/db/products'

  initialize: (models, options) ->
    options ?= {}
    options.url ?= '/db/products?path=' + window.location.pathname if window?.location?.pathname
    super models, options

  getByName: (name) -> @findWhere { name: name }

  getBasicSubscriptionForUser: (user) ->
    coupon = user?.get('stripe')?.couponID
    if coupon
      countrySpecificProduct = @findWhere { name: "#{coupon}_basic_subscription" }
    unless countrySpecificProduct
      countrySpecificProduct = @findWhere { name: "#{user?.get('country')}_basic_subscription" }
    return countrySpecificProduct or @findWhere({ name: 'basic_subscription' })

  getBasicAnnualSubscriptionForUser: () ->
    return @findWhere({ name: 'basic_subscription_annual' })

  getLifetimeSubscriptionForUser: (user) ->
    country = (user?.get('country') or '').toLowerCase()
    if country == "hong-kong" or country == "taiwan"
      return null

    coupon = user?.get('stripe')?.couponID
    if coupon
      countrySpecificProduct = @findWhere { name: "#{coupon}_lifetime_subscription" }
    unless countrySpecificProduct
      countrySpecificProduct = @findWhere { name: "#{user?.get('country')}_lifetime_subscription" }
    return countrySpecificProduct or @findWhere({ name: 'lifetime_subscription' })
