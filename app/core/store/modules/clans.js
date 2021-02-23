import { getPublicClans, getMyClans, getClan, getChildClanDetails } from '../../api/clans'

export default {
  namespaced: true,
  state: {
    // key is clan id, with clan data stored as object literal.
    clans: {},
    // key is the clan id that initiated the request. Response array is memoized.
    childClanDetails: {},
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
    },

    childClanDetails (state) {
      return id => {
        return state.childClanDetails[id] || []
      }
    }
  },

  mutations: {
    setClan (state, clan) {
      // We do not want to overwrite a clan with a version of the clan with less fields.
      // This can result in a clan losing a displayName and showing the slug as a result.
      if (state.clans[clan._id] && Object.keys(state.clans[clan._id]).length > Object.keys(clan).length) {
        return
      }

      Vue.set(state.clans, clan._id, clan)
    },

    setClanDetails (state, { clanId, childClans }) {
      Vue.set(state.childClanDetails, clanId, childClans)
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
    },

    async fetchChildClanDetails ({ commit }, { id }) {
      const childClans = await getChildClanDetails(id)
      commit('setClanDetails', { clanId: id, childClans })
    }
  }
}
