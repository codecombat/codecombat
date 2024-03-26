// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let Products
const CocoCollection = require('./CocoCollection')
const Product = require('models/Product')

// This collection is also used by the Vuex products module, ideally we would
// transfer the logic in this collection to the Vuex module but we're not doing
// active work on this product so leaving as is for now.
module.exports = (Products = (function () {
  Products = class Products extends CocoCollection {
    static initClass () {
      this.prototype.model = Product
      this.prototype.url = '/db/products'
    }

    initialize (models, options) {
      if (options == null) { options = {} }
      if (__guard__(typeof window !== 'undefined' && window !== null ? window.location : undefined, x => x.pathname)) { if (options.url == null) { options.url = '/db/products?path=' + window.location.pathname } }
      return super.initialize(models, options)
    }

    getByName (name) { return this.findWhere({ name }) }

    getBasicSubscriptionForUser (user) {
      if (features.chinaHome) {
        return this.findWhere({ name: 'china_monthly_subscription' })
      } else if (features.chinaInfra) { return null }

      let countrySpecificProduct
      const coupon = __guard__(user != null ? user.get('stripe') : undefined, x => x.couponID)
      if (coupon) {
        countrySpecificProduct = this.findWhere({ name: `${coupon}_basic_subscription` })
      }
      if (!countrySpecificProduct) {
        countrySpecificProduct = this.findWhere({ name: 'corrily_basic_subscription' } || this.findWhere({ name: `corrily_${(user != null ? user.get('country') : undefined)}_basic_subscription` }))
      }
      if (!countrySpecificProduct) {
        countrySpecificProduct = this.findWhere({ name: `${(user != null ? user.get('country') : undefined)}_basic_subscription` })
      }
      console.log('product selected', countrySpecificProduct)
      return countrySpecificProduct || this.findWhere({ name: 'basic_subscription' })
    }

    getBasicAnnualSubscriptionForUser () {
      if (features.chinaHome) {
        return this.findWhere({ name: 'china_annual_subscription' })
      } else if (features.chinaInfra) { return null }

      const corrilyAnnual = this.findWhere({ name: 'corrily_basic_subscription_annual' })
      console.log('product annual sel', corrilyAnnual)
      return corrilyAnnual || this.findWhere({ name: 'basic_subscription_annual' })
    }

    getLifetimeSubscriptionForUser (user) {
      let countrySpecificProduct
      const country = ((user != null ? user.get('country') : undefined) || '').toLowerCase()
      if ((country === 'hong-kong') || (country === 'taiwan')) {
        return null
      }

      const coupon = __guard__(user != null ? user.get('stripe') : undefined, x => x.couponID)
      if (coupon) {
        countrySpecificProduct = this.findWhere({ name: `${coupon}_lifetime_subscription` })
      }
      if (!countrySpecificProduct) {
        countrySpecificProduct = this.findWhere({ name: `${(user != null ? user.get('country') : undefined)}_lifetime_subscription` })
      }
      return countrySpecificProduct || this.findWhere({ name: 'lifetime_subscription' })
    }
  }
  Products.initClass()
  return Products
})())

function __guard__ (value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined
}
