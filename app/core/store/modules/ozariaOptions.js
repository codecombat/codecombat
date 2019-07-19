export default {
  namespaced: true,

  state: {
    soundOn: true
  },

  mutations: {
    toggleSound (state) { state.soundOn = !state.soundOn }
  },

  getters: {
    isSoundOn (state) {
      return state.soundOn
    }
  },

  actions: {
    toggleSoundAction ({ commit }) {
      commit('toggleSound')
    }
  }
}
