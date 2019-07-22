export default {
  namespaced: true,

  state () {
    // TODO: Currently saving volume to session instead of database.
    let cachedSound
    if (window.sessionStorage) {
      cachedSound = window.sessionStorage.getItem('layoutChrome/soundOn')
    }

    return {
      soundOn: cachedSound !== 'false',
      currentCourseInstanceId: null,
      currentCampaignId: null
    }
  },

  mutations: {
    toggleSound (state) {
      Vue.set(state, 'soundOn', !state.soundOn)
      if (window.sessionStorage) {
        window.sessionStorage.setItem('layoutChrome/soundOn', state.soundOn)
      }
    },
    setCourseInstanceId (state, courseInstanceId) { Vue.set(state, 'currentCourseInstanceId', courseInstanceId) },
    setCurrentCampaignId (state, campaignId) { Vue.set(state, 'currentCampaignId', campaignId) }
  },

  getters: {
    isSoundOn (state) {
      return state.soundOn
    },

    getCurrentCampaignId (state) {
      return state.currentCampaignId
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
    },

    setCurrentCampaignId ({ commit }, campaignId) {
      commit('setCurrentCampaignId', campaignId)
    }
  }
}
