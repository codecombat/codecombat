import { getAllTints } from '../../../../ozaria/site/api/tint'

export default {
  namespaced: true,

  state: {
    loading: false,
    tints: []
  },

  mutations: {
    toggleLoading (state) { state.loading = !state.loading },

    addTints (state, tints) { Vue.set(state, 'tints', tints) }
  },

  getters: {
    characterCustomizationTints (state) {
      return state.tints
    }
  },

  actions: {
    async fetchTints ({ commit }) {
      commit('toggleLoading')
      try {
        const tints = await getAllTints()
        commit('addTints', tints)
      } catch (e) {
        // TODO handle_error_ozaria
        noty({ text: 'Fetch tints failure', type: 'error' })
        commit('toggleLoading')
      }

    }
  }
}
