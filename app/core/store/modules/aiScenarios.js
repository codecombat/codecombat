const api = require('core/api')

export default {
  namespaced: true,

  state: {
    loaded: false,
    byId: {},
  },

  getters: {
    getScenarios (state) {
      const scenarios = _.values(state.byId)
      return scenarios
    },
  },

  mutations: {
    addScenarios (state, scenarios) {
      for (const scenario of scenarios) {
        Vue.set(state.byId, scenario._id, scenario)
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
