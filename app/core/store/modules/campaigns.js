import campaignsApi from 'core/api/campaigns'

export default {
  namespaced: true,

  state: {
    loading: {
      byHandle: {}
    },

    byHandle: {}
  },

  mutations: {
    toggleLoadingByHandle: (state, handle) =>
      Vue.set(state.loading.byHandle, handle, !state.loading.byHandle[handle]),

    addCampaignByHandle: (state, { handle, campaign }) =>
      Vue.set(state.byHandle, handle, campaign)
  },

  actions: {
    async fetchByHandle ({ commit }, handle) {
      commit('toggleLoadingByHandle', 'handle')

      try {
        const campaign = await campaignsApi.get(handle)
        if (campaign) {
          commit('addCampaignByHandle', {
            handle,
            campaign
          })

          return campaign
        }

        throw new Error('Unexpected response format from campaign API')
      } catch (e) {
        // TODO handle
      } finally {
        commit('toggleLoadingByHandle', 'handle')
      }
    }
  }
}
