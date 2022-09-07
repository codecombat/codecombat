import campaignsApi from 'core/api/campaigns'
import utils from 'core/utils'
import Campaign from 'models/Campaign'

export default {
  namespaced: true,
  state: utils.isOzaria ? {
    campaignByCampaignHandle: {},
    campaignById: {},
    campaignBySlug: {},
    campaignByCourseInstanceId: {},
    campaignByCourseId: {}
  } : {
    byId: {},
    bySlug: {},
    currentCampaignId: null
  },

  mutations: {
    setCampaignData: utils.isOzaria ?
      (state, { campaignData, campaignHandle, courseInstanceId, courseId }) => {
          Vue.set(state.campaignByCampaignHandle, campaignHandle, campaignData)
          Vue.set(state.campaignById, campaignData._id, campaignData)
          Vue.set(state.campaignBySlug, campaignData.slug, campaignData)
          Vue.set(state.campaignByCourseInstanceId, courseInstanceId, campaignData)
          Vue.set(state.campaignByCourseId, courseId, campaignData)
        } : (state, campaignData) => {
          Vue.set(state.byId, campaignData._id, campaignData)
          Vue.set(state.bySlug, campaignData.slug, campaignData)
          state.currentCampaignId = campaignData._id
        }
  },

  getters: {
    getCampaignData: utils.isOzaria ? (state) => ({ idOrSlug, campaignHandle, courseInstanceId, courseId }) => {
        return state.campaignById[idOrSlug] ||
          state.campaignBySlug[idOrSlug] ||
          state.campaignByCampaignHandle[campaignHandle] ||
          state.campaignByCourseInstanceId[courseInstanceId] ||
          state.campaignByCourseId[courseId]
      } : (state) => (idOrSlug) => {
        return state.byId[idOrSlug] || state.bySlug[idOrSlug]
      },
    getCurrentCampaignId: (state) => state.currentCampaignId
  },

  actions: {
    fetch: utils.isOzaria ? async ({ commit, state, rootGetters, dispatch }, { campaignHandle, courseInstanceId, courseId }) => {
        if (state.campaignById[campaignHandle] ||
          state.campaignBySlug[campaignHandle] ||
          state.campaignByCampaignHandle[campaignHandle] ||
          state.campaignByCourseInstanceId[courseInstanceId] ||
          state.campaignByCourseId[courseId]) {
          return
        }

        let campaignData

        // Turning off the extra-sensitive fetching of campaigns from course instances and classrooms as an easy way of reverting campaign versioning. TODO: delete this and related code?
        if (false && courseInstanceId) {
          let classroom = rootGetters['classrooms/getClassroomByCourseInstanceId'](courseInstanceId)
          if (!classroom) {
            await dispatch('classrooms/fetchClassroomForCourseInstanceId', courseInstanceId, { root: true })
            classroom = rootGetters['classrooms/getClassroomByCourseInstanceId'](courseInstanceId)
          }

          if (classroom) {
            campaignData = classroom.courses.find(c => c._id === courseId)?.campaign
            if (!campaignData) {
              console.error('We found the course but not the campaign, data sync mismatch for courseInstanceId: ', courseInstanceId)
              noty({ text: 'Fetch campaign failure', type: 'error' })
            }
          }
        }

        if (!campaignData) {
          // Without a classroom we are dealing with HoC, and have to hit the server to get the campaign:
          try {
            campaignData = await campaignsApi.get({ campaignHandle: campaignHandle })
          } catch (e) {
            console.error('Error in fetching campaign', e)
            // TODO: update after a consistent error handling strategy is decided
            noty({ text: 'Fetch campaign failure', type: 'error' })
          }
        }

        // Default the campaignPage value as 1 in campaign data for backward compatibility
        if (campaignData.backgroundImage) {
          campaignData.backgroundImage.filter(b => !b.campaignPage).map(b => { b.campaignPage = 1 })
        }

        // Delete inaccessible levels based on releasePhase
        const accessibleLevelsOriginal = new Set(Campaign.getLevels(campaignData).map(l => l.original))
        const removeLevelsOriginal = Object.keys(campaignData.levels).filter(l => !accessibleLevelsOriginal.has(l))
        removeLevelsOriginal.forEach(l => delete campaignData.levels[l])

        Object.values(campaignData.levels)
        .filter(l => !l.campaignPage)
        .map(l => { l.campaignPage = 1 })

        commit('setCampaignData', { campaignData, campaignHandle, courseInstanceId, courseId })
      } : async ({ commit, state }, campaignHandle) => {
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
