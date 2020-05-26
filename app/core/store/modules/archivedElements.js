export default {
  namespaced: true,

  state: {
    searchTerm: '',
    elementType: 'ThangType'
  },

  getters: {
    searchTerm: (state) => state.searchTerm,
    elementType: (state) => state.elementType
  },

  mutations: {
    setSearchTerm: (state, searchTerm) => state.searchTerm = searchTerm,
    setElementType: (state, elementType) => state.elementType = elementType
  },

  actions: {
    setSearchTerm: ({ commit, rootState }, searchTerm) => {
      commit('setSearchTerm', searchTerm)
    },
    setElementType: ({ commit, rootState }, elementType) => {
      commit('setElementType', elementType)
    }
  }
}

