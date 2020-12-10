import { getPublicClans, getMyClans } from '../../api/clans'

export default {
  namespaced: true,
  state: {
    // key is clan id, with clan data stored as object literal.
    clans: {},
    loading: false
  },

  getters: {
    myClans (state) {
      return (me.get('clans') || []).map(id => state.clans[id])
    }
  },

  mutations: {
    setClan (state, clan) {
      Vue.set(state.clans, clan._id, clan)
    }
  },

  actions: {
    async fetchMyClans ({ commit }) {
      const clans = await getMyClans()
      for (const clan of clans) {
        commit('setClan', clan)
      }
      console.log('myclans:', clans)
      
    },

    async fetchPublicClans ({ commit }) {
      const clans = await getPublicClans()
      for (const clan of clans) {
        commit('setClan', clan)
      }
    }
  }
}
