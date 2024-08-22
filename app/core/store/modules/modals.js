export default {
  namespaced: true,
  state: {
    modals: [],
  },
  mutations: {
    addModal (state, modal) {
      const index = state.modals.findIndex(m => m.name === modal.name)
      if (index === -1) {
        state.modals.push(modal)
      } else {
        // Remove the modal from its current position
        const [existingModal] = state.modals.splice(index, 1)
        // Push the existing modal to the end of the array
        state.modals.push(existingModal)
      }
    },
    removeModal (state, modalName) {
      const index = state.modals.findIndex(m => m.name === modalName)
      if (index !== -1) {
        state.modals.splice(index, 1)
      }
    },
  },
  getters: {
    getTopModal: (state) => {
      return state.modals[state.modals.length - 1]
    },
  },
}
