const api = require('core/api')

export default {
  namespaced: true,

  state: {
    loaded: false,
    byId: {},
    byOriginal: {},
  },

  getters: {
    getScenarios (state) {
      const scenarios = _.values(state.byOriginal)
      return scenarios
    },
  },

  mutations: {
    addScenarios (state, scenarios) {
      for (const scenario of scenarios) {
        Vue.set(state.byId, scenario._id, scenario) // in case i'm missing some usage with byId, doesn't delete it for now
        Vue.set(state.byOriginal, scenario.Original, scenario)
      }
    },
  },

  actions: {
    async fetchReleased ({ commit, state }, options) {
      const effectiveOptions = options || {}
      const scenarios = await api.aiScenarios.getReleased(effectiveOptions)
      commit('addScenarios', scenarios)
    }
  }
}
