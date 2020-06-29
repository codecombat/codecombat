export default {
  namespaced: true,

  state () {
    // TODO: Currently saving volume to session instead of database.
    // TODO: Investigate using vuex-persist for caching state.
    let cachedSound
    if (window.sessionStorage) {
      cachedSound = window.sessionStorage.getItem('layoutChrome/soundOn')
    }

    return {
      soundOn: cachedSound !== 'false',
      // TODO: Move this into a dedicated courseInstance module
      currentCourseInstanceId: null
    }
  },

  mutations: {
    toggleSound (state) {
      state.soundOn = !state.soundOn
      if (window.sessionStorage) {
        window.sessionStorage.setItem('layoutChrome/soundOn', state.soundOn)
      }
    },

    setCourseInstanceId (state, courseInstanceId) { Vue.set(state, 'currentCourseInstanceId', courseInstanceId) },
  },

  getters: {
    soundOn (state) {
      return state.soundOn
    },

    getMapUrl (state, _getters, _rootState, rootGetters) {
      const campaignId = rootGetters['campaigns/getCurrentCampaignId']
      const courseInstanceId = state.currentCourseInstanceId

      if (!(campaignId && courseInstanceId)) {
        return undefined
      }
      return `/ozaria/play/${campaignId}?course-instance=${courseInstanceId}`
    },

    getCurrentCourseInstanceId (state) {
      return state.currentCourseInstanceId
    }
  },

  actions: {
    toggleSoundAction ({ commit }) {
      commit('toggleSound')
    },

    setCurrentCourseInstanceId ({ commit }, courseInstanceId) {
      commit('setCourseInstanceId', courseInstanceId)
    }
  }
}
