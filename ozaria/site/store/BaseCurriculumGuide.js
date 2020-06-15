
export default {
  namespaced: true,

  state: () => ({
    visible: false
  }),

  mutations: {
    openCurriculumGuide (state) {
      state.visible = true
    },
    closeCurriculumGuide (state) {
      state.visible = false
    }
  },

  actions: {
    toggleCurriculumGuide ({ state, commit }) {
      if (state.visible) {
        commit('closeCurriculumGuide')
      } else {
        commit('openCurriculumGuide')
      }
    }
  }
}
