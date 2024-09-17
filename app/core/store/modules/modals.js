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
        state.modals.sort((a, b) => b.priority - a.priority)
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
      const topModal = state.modals[0]

      // If there's no top modal, return null
      if (!topModal) {
        return null
      }

      // If the top modal isn't restricted  by a seenPromotionsProperty, show it
      if (!topModal.seenPromotionsProperty) {
        return topModal
      }

      // If the user should see the promotion, return the top modal
      if (me.shouldSeePromotion(topModal.seenPromotionsProperty)) {
        return topModal
      }

      // If none of the above conditions are met, return null
      return null
    },
  },
}
