export default {
  namespaced: true,

  state: {
    searchTerm: '',
    elementType: 'ThangType',
    displayArchived: 'none' // none, only, both
  },

  getters: {
    searchTerm: (state) => state.searchTerm,
    elementType: (state) => state.elementType,
    displayArchived: (state) => state.displayArchived
  },

  mutations: {
    setSearchTerm: (state, searchTerm) => state.searchTerm = searchTerm,
    setElementType: (state, elementType) => state.elementType = elementType,
    // none, only, both
    setDisplayArchived: (state, displayArchived) => state.displayArchived = displayArchived
  },

  actions: {
    setSearchTerm: ({ commit, rootState }, searchTerm) => {
      commit('setSearchTerm', searchTerm)
    },
    setElementType: ({ commit, rootState }, elementType) => {
      commit('setElementType', elementType)
    },
    // none, only, both
    setDisplayArchived: ({ commit, rootState }, displayArchived) => {
      commit('setDisplayArchived', displayArchived)
    }
  }
}

