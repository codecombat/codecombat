import Products from 'app/collections/Products'

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
    loadProducts ({ commit }) {
      commit('toggleLoadingProducts')

      const productsRequest = new Products().fetch()
      productsRequest.done(products => commit('addProducts', { products }))
      productsRequest.fail(() => noty({ text: 'Failed to load product pricing', type: 'error' }))
      productsRequest.always(() => commit('toggleLoadingProducts'))
    }
  },

  getters: {
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
