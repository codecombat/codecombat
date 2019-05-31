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

  actions: {
    fetch: ({ commit, state }, campaignHandle) => {
      if (state.byId.campaignHandle || state.bySlug.campaignHandle) {
        return Promise.resolve()
      }
      return campaignsApi.get({ campaignHandle: campaignHandle })
        .then(res => commit('setCampaignData', res))
        .catch((e) => {
          console.error('Error in fetching campaign', e)
          noty({ text: 'Fetch campaign failure', type: 'error' })
        })
    }
  }
}
