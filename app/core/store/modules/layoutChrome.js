export default {
  namespaced: true,

  state: {
    soundOn: true,
    currentCourseInstanceId: null,
    currentCampaignId: null
  },

  mutations: {
    toggleSound (state) { Vue.set(state, 'soundOn', !state.soundOn ) },
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
