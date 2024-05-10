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
      scenarios.forEach(c => Vue.set(state.byId, c._id, c))
    },
  },

  actions: {
    async fetchReleased ({ commit, state }, options) {
      if (options == null) { options = {} }
      const scenarios = await api.aiScenarios.getReleased(options)
      const filteredScenarios = scenarios.filter(scenario => scenario.releasePhase === 'released')
      commit('addScenarios', filteredScenarios)
    }
  }
}
