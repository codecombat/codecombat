import urls from 'app/core/urls'
import utils from 'app/core/utils'

export default {
  namespaced: true,

  state () {
    // TODO: Currently saving volume to session instead of database.
    // TODO: Investigate using vuex-persist for caching state.
    let cachedSound
    if (window.sessionStorage) {
      cachedSound = window.sessionStorage.getItem('layoutChrome/soundOn')
    }

    return {
      soundOn: cachedSound !== 'false',
      // TODO: Move this into a dedicated courseInstance, and course module like the currentCampaignId in campaigns module
      currentCourseInstanceId: null,
      currentCourseId: null
    }
  },

  mutations: {
    toggleSound (state) {
      state.soundOn = !state.soundOn
      if (window.sessionStorage) {
        window.sessionStorage.setItem('layoutChrome/soundOn', state.soundOn)
      }
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
