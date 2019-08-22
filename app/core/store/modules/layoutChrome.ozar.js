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
      // TODO: Move this into a dedicated courseInstance, and course module like the currentCampaignId in campaigns module
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

    setUnitMapUrlDetails (state, payload) {
      Vue.set(state, 'currentCourseId', payload.courseId)
      Vue.set(state, 'currentCourseInstanceId', payload.courseInstanceId)
    }
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
    }
  },

  actions: {
    toggleSoundAction ({ commit }) {
      commit('toggleSound')
    }
  }
}
