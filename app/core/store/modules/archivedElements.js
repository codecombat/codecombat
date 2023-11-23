const displayArchivedTypes = ['none', 'only', 'both']

export default {
  namespaced: true,

  state: {
    searchTerm: '',
    elementType: 'ThangType',
    displayArchived: 'none'
  },

  getters: {
    searchTerm: (state) => state.searchTerm,
    elementType: (state) => state.elementType,
    displayArchived: (state) => state.displayArchived
  },

  mutations: {
    setSearchTerm: (state, searchTerm) => {
      state.searchTerm = searchTerm
    },
    setElementType: (state, elementType) => {
      state.elementType = elementType
    },
    setDisplayArchived: (state, displayArchived) => {
      if (displayArchivedTypes.indexOf(displayArchived) === -1) {
        throw new Error(`Cannot mutate displayedArchive to ${displayArchived}`)
      }
      state.displayArchived = displayArchived
    }
  },

  actions: {
    setSearchTerm: ({ commit, rootState }, searchTerm) => {
      commit('setSearchTerm', searchTerm)
    },
    setElementType: ({ commit, rootState }, elementType) => {
      commit('setElementType', elementType)
    },
    setDisplayArchived: ({ commit, rootState }, displayArchived) => {
      commit('setDisplayArchived', displayArchived)
    }
  }
}
