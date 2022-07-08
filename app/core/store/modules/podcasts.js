import { getPodcasts, getPodcast } from '../../api/podcast'

const comparePodcastFn = (a, b) => {
  // higher priority podcast should come up at top
  if (a.priority || b.priority)
    return (b.priority || 0) - (a.priority || 0)
  const aDate = a.uploadDate ? new Date(a.uploadDate).getTime() : 0
  const bDate = b.uploadDate ? new Date(b.uploadDate).getTime() : 0
  return bDate - aDate
}
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
      state.podcasts = [...podcasts.sort(comparePodcastFn)]
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
