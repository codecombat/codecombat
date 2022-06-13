import { getPodcasts, getPodcast } from '../../api/podcast'

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
    },
    setPodcast (state, podcast) {
      const index = state.podcasts.findIndex(p => p.id === podcast.id)
      if (index === -1) {
        state.podcasts.push(podcast)
      } else {
        state.podcasts.splice(index, 1, podcast)
      }
    }
  },
  getters: {
    podcasts (state) {
      return state.podcasts
    },
    podcast: (state) => (handle) => {
      return state.podcasts.find(p => p._id === handle || p.slug === handle)
    }
  },
  actions: {
    async fetchAll ({ commit }) {
      commit('setLoading', true)

      const result = await getPodcasts()
      commit('setPodcasts', result)
      commit('setLoading', false)
    },
    async fetch ({ commit }, { podcastId }) {
      const podcast = await getPodcast(podcastId)
      commit('setPodcast', podcast)
    }
  }
}
