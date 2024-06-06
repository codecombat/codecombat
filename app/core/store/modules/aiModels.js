const api = require('core/api')

export default {
  namespaced: true,

  state: {
    loaded: false,
    byId: {},
    byName: {}
  },

  getters: {
    getModels (state) {
      const models = _.values(state.byId)
      return models
    },
    getModelsByName (state) {
      return state.byName
    }
  },

  mutations: {
    add (state, models) {
      for (const model of models) {
        Vue.set(state.byId, model._id, model)
        Vue.set(state.byName, model.name, model)
      }
    },
  },

  actions: {
    async fetch ({ commit, state }) {
      const models = await api.aiModels.getAll()
      commit('add', models)
    }
  }
}
