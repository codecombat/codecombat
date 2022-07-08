import Products from 'app/collections/Products'
import _ from 'lodash'
const utils = require('core/utils')

/**
 * This module acts as a simple proxy to the Products collection.  Ideally we'd move the products
 * logic to this module but for now it allows the products module to be called via Vue components.
 */
export default {
  namespaced: true,

  state: {
    loading: {
      products: false
    },

    products: []
  },

  mutations: {
    toggleLoadingProducts: (state) => {
      state.loading.products = !state.loading.products
    },

    addProducts (state, { products }) {
      state.products = products
    }
  },

  actions: {
    loadProducts ({ commit, getters }) {
      commit('toggleLoadingProducts')

      const data = {}
      if (getters.activeCouponID) {
        data.coupon = getters.activeCouponID
      }

      const productsRequest = new Products().fetch({ data })
      productsRequest.done(products => commit('addProducts', { products }))
      productsRequest.fail(() => noty({ text: 'Failed to load product pricing', type: 'error' }))
      productsRequest.always(() => commit('toggleLoadingProducts'))
    }
  },

  getters: {
    activeCouponID () {
      const couponID = utils.getQueryVariable('coupon') || me.get('country')
      if (couponID === 'brazil') {
        // Edge case due to misconfigured brazil coupon in stripe that is immutable
        return 'brazil-annual'
      }
      return couponID
    },

    basicSubscriptionForCurrentUser (state) {
      if (!Array.isArray(state.products) || state.products.length === 0) {
        return undefined
      }

      const productsCollection = new Products()
      productsCollection.add(state.products)

      return productsCollection.getBasicSubscriptionForUser(window.me).toJSON()
    },

    basicAnnualSubscriptionForCurrentUser (state) {
      if (!Array.isArray(state.products) || state.products.length === 0) {
        return undefined
      }

      const productsCollection = new Products()
      productsCollection.add(state.products)

      return productsCollection.getBasicAnnualSubscriptionForUser(window.me).toJSON()
    },

    // Returns price of basic annual subscription modified by coupon
    basicAnnualSubscriptionPrice (_state, getters) {
      if (!getters.basicAnnualSubscriptionForCurrentUser || !getters.activeCouponID) {
        // Default price of product. Can safely show while loading.
        return 99
      }

      const coupon = _.find(getters.basicAnnualSubscriptionForCurrentUser.coupons, { code: getters.activeCouponID })

      if (!coupon) {
        return 99
      }

      const amount = parseInt(coupon.amount, 10)
      if (!isNaN(amount)) {
        return (coupon.amount / 100).toFixed(2)
      }

      return 99
    },

    lifetimeSubscriptionForCurrentUser (state) {
      if (!Array.isArray(state.products) || state.products.length === 0) {
        return undefined
      }

      const productsCollection = new Products()
      productsCollection.add(state.products)

      return productsCollection.getLifetimeSubscriptionForUser(window.me).toJSON()
    }
  }
}
