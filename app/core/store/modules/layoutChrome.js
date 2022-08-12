import urls from 'app/core/urls'
import utils from 'app/core/utils'

export default {
  namespaced: true,

  state () {
    return {
      // TODO: sync this from store me module instead of the actual Backbone object
      soundOn: me.get('volume', true) > 0,
      // TODO: Move this into a dedicated courseInstance, and course module like the currentCampaignId in campaigns module
      currentCourseInstanceId: null,
      currentCourseId: null
    }
  },

  mutations: {
    toggleSound (state) {
      state.soundOn = !state.soundOn

      // Also propagate this update to older Backbone/User volume settings
      me.set('volume', state.soundOn ? 1 : 0)
      me.patch()
      Backbone.Mediator.publish('level:set-volume', { volume: me.get('volume') })
    },

    setUnitMapUrlDetails (state, payload) {
      Vue.set(state, 'currentCourseId', payload.courseId)
      Vue.set(state, 'currentCourseInstanceId', payload.courseInstanceId)
    }
  },

  getters: {
    soundOn (state) {
      return state.soundOn
    },

    getMapUrl (state, _getters, _rootState, rootGetters) {
      const courseInstanceId = state.currentCourseInstanceId
      const courseId = state.currentCourseId
      const campaign = rootGetters['campaigns/getCampaignData']({ courseInstanceId, courseId })
      if (!campaign) {
        return undefined
      }
      const url = urls.courseWorldMap({
        courseId: courseId,
        courseInstanceId: courseInstanceId,
        campaignId: campaign.slug,
        codeLanguage: utils.getQueryVariable('codeLanguage')
      })
      return url
    }
  },

  actions: {
    toggleSoundAction ({ commit, dispatch }) {
      commit('toggleSound')
      dispatch('syncSoundToAudioSystem')
    },

    syncSoundToAudioSystem ({ dispatch, state }) {
      if (state.soundOn) {
        dispatch('audio/unmuteAll', undefined, { root: true })
      } else {
        dispatch('audio/muteAll', undefined, { root: true })
      }
    }
  }
}
