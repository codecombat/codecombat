import campaignsApi from 'core/api/campaigns'

export default {
  namespaced: true,
  state: {
    byId: {},
    bySlug: {},
    currentCampaignId: null
  },

  mutations: {
    setCampaignData: (state, campaignData) => {
      Vue.set(state.byId, campaignData._id, campaignData)
      Vue.set(state.bySlug, campaignData.slug, campaignData)
    },

    setCurrentCampaignId: (state, campaignId) => {
      state.currentCampaignId = campaignId
    }
  },

  getters: {
    getCampaignData: (state) => (idOrSlug) => {
      return state.byId[idOrSlug] || state.bySlug[idOrSlug]
    },
    getCurrentCampaignId: (state) => state.currentCampaignId
  },

  actions: {
    fetch: async ({ commit, state }, campaignHandle) => {
      if (state.byId[campaignHandle] || state.bySlug[campaignHandle]) {
        return
      }
      try {
        const campaignData = await campaignsApi.get({ campaignHandle: campaignHandle })
        // Default the campaignPage value as 1 in campaign data for backward compatibility
        if (campaignData.backgroundImage) {
          campaignData.backgroundImage.filter(b => !b.campaignPage).map(b => { b.campaignPage = 1 })
        }
        Object.values(campaignData.levels)
          .filter(l => !l.campaignPage)
          .map(l => { l.campaignPage = 1 })

        commit('setCampaignData', campaignData)
      } catch (e) {
        console.error('Error in fetching campaign', e)
        // TODO: update after a consistent error handling strategy is decided
        noty({ text: 'Fetch campaign failure', type: 'error' })
      }
    }
  }
}
