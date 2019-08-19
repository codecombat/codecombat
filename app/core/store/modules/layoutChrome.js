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
      // TODO: Move this into a dedicated courseInstance, and course module
      currentCourseInstanceId: null,
      currentCourseId: null
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

    setCourseId (state, courseId) { Vue.set(state, 'currentCourseId', courseId) }
  },

  getters: {
    soundOn (state) {
      return state.soundOn
    },

    getMapUrl (state, _getters, _rootState, rootGetters) {
      const campaignId = rootGetters['campaigns/getCurrentCampaignId']
      const courseInstanceId = state.currentCourseInstanceId
      const courseId = state.currentCourseId
      if (!campaignId) {
        return undefined
      }
      let url = `/play/${campaignId}`

      if (courseId) {
        url += `?course=${courseId}`
        if (courseInstanceId) {
          url += `&course-instance=${courseInstanceId}`
        }
      } else if (courseInstanceId) {
        url += `?course-instance=${courseInstanceId}`
      }
      return url
    },

    getCurrentCourseInstanceId (state) {
      return state.currentCourseInstanceId
    },

    getCurrentCourseId (state) {
      return state.currentCourseId
    }
  },

  actions: {
    toggleSoundAction ({ commit }) {
      commit('toggleSound')
    },

    setCurrentCourseInstanceId ({ commit }, courseInstanceId) {
      commit('setCourseInstanceId', courseInstanceId)
    },

    setCurrentCourseId ({ commit }, courseId) {
      commit('setCourseId', courseId)
    }
  }
}
