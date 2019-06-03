import campaignsApi from 'core/api/campaigns'

export default {
  namespaced: true,
  state: {
    byId: {},
    bySlug: {}
  },

  mutations: {
    setCampaignData: (state, campaignData) => {
      Vue.set(state.byId, campaignData._id, campaignData)
      Vue.set(state.bySlug, campaignData.slug, campaignData)
    }
  },

  getters: {
    getCampaignData: (state) => (idOrSlug) => {
      return state.byId[idOrSlug] || state.bySlug[idOrSlug]
    }
  },

  actions: {
    fetch: async ({ commit, state }, campaignHandle) => {
      if (state.byId[campaignHandle] || state.bySlug[campaignHandle]) {
        return
      }
      try {
        const campaignData = await campaignsApi.get({ campaignHandle: campaignHandle })
        commit('setCampaignData', campaignData)
      } catch (e) {
        console.error('Error in fetching campaign', e)
        // TODO: update after a consistent error handling strategy is decided
        noty({ text: 'Fetch campaign failure', type: 'error' })
      }
    }
  }
}
