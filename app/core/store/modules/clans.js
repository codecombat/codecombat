import { getPublicClans, getMyClans, getClan } from '../../api/clans'

export default {
  namespaced: true,
  state: {
    // key is clan id, with clan data stored as object literal.
    clans: {},
    loading: false
  },

  getters: {
    isLoading (state) {
      return state.loading
    },

    myClans (state) {
      return (me.get('clans') || []).map(id => state.clans[id])
    },

    clanByIdOrSlug (state) {
      return idOrSlug => {
        return state.clans[idOrSlug] || Object.values(state.clans).find(({ slug }) => slug === idOrSlug)
      }
    }
  },

  mutations: {
    setClan (state, clan) {
      Vue.set(state.clans, clan._id, clan)
    },

    setLoading (state, loading) {
      state.loading = loading
    }
  },

  actions: {
    async fetchRequiredInitialData ({ commit, dispatch }, { optionalIdOrSlug }) {
      commit('setLoading', true)
      try {
        const fetchPromises = [dispatch('fetchMyClans'), dispatch('fetchPublicClans')]
        if (optionalIdOrSlug) {
          fetchPromises.push(dispatch('fetchClan', { idOrSlug: optionalIdOrSlug }))
        }
        await Promise.all(fetchPromises)
      } catch (e) {
        console.error(e)
      }
      commit('setLoading', false)
    },

    async fetchMyClans ({ commit }) {
      const clans = await getMyClans()
      for (const clan of clans) {
        commit('setClan', clan)
      }
    },

    async fetchClan ({ commit }, { idOrSlug }) {
      const clan = await getClan(idOrSlug)
      if (clan) {
        commit('setClan', clan)
      }
    },

    async fetchPublicClans ({ commit }) {
      const clans = await getPublicClans()
      for (const clan of clans) {
        commit('setClan', clan)
      }
    }
  }
}
