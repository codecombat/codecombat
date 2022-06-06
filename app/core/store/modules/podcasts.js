import { getPodcasts } from '../../api/podcast'

export default {
  namespaced: true,
  state: {
    loading: null,
    podcasts: []
  },
  mutations: {
    setLoading (state, loading) {
      state.loading = loading
    },
    setPodcasts (state, podcasts) {
      state.podcasts = [...podcasts]
    }
  },
  getters: {
    podcasts (state) {
      return state.podcasts
    }
  },
  actions: {
    async fetchAll ({ commit }) {
      commit('setLoading', true)

      const result = await getPodcasts()
      commit('setPodcasts', result)
      commit('setLoading', false)
    }
  }
}
