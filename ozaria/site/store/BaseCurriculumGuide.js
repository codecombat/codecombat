import urls from 'app/core/urls'
import utils from 'app/core/utils'

export default {
  namespaced: true,

  state: () => ({
    visible: false,
    selectedCampaignId: undefined,
    selectedLanguage: 'python'
  }),

  mutations: {
    openCurriculumGuide (state) {
      state.visible = true
    },

    closeCurriculumGuide (state) {
      state.visible = false
    },

    setSelectedCampaignId (state, campaignID) {
      state.selectedCampaignId = campaignID
    },

    setSelectedLanguage (state, language) {
      state.selectedLanguage = language
    }
  },

  getters: {
    chapterNavBar (_state, _getters, _rootState, rootGetters) {
      const courses = rootGetters['courses/sorted'] || []
      return courses
    },

    selectedChapterId (state) {
      return state.selectedCampaignId
    },

    getCurrentCourse (_state, getters, _rootState, rootGetters) {
      if (!getters.selectedChapterId || !rootGetters['courses/sorted']) {
        return
      }

      const courses = rootGetters['courses/sorted']
      return courses.find(({ campaignID }) => campaignID === getters.selectedChapterId)
    },

    getCapstoneInfo (_state, getters, _rootState, rootGetters) {
      const gameContent = rootGetters['gameContent/getContentForCampaign'](getters.selectedChapterId)
      return gameContent?.capstone
    },

    getModuleInfo (_state, getters, _rootState, rootGetters) {
      const gameContent = rootGetters['gameContent/getContentForCampaign'](getters.selectedChapterId)
      return gameContent?.modules
    },

    getCurrentModuleNames (_state, getters, _rootState, _rootGetters) {
      return  moduleNum => {
        const course = getters.getCurrentCourse
        return utils.courseModules[course._id]?.[moduleNum]
      }
    },

    // Returns either the module info from the course or an empty object.
    getCurrentModuleHeadingInfo (_state, getters, _rootState, _rootGetters) {
      return moduleNum => {
        const course = getters.getCurrentCourse
        let moduleNumber = moduleNum
        if (typeof moduleNumber === 'string') {
          moduleNumber = parseInt(moduleNum)
        }

        const moduleInfo = Object.values(course.modules || {}).find(({ number }) => number === moduleNumber)
        return moduleInfo || {}
      }
    },

    getCourseUnitMapUrl (state, getters, _rootState) {
      if (!getters.getCurrentCourse) {
        return
      }

      return urls.courseWorldMap({
        courseId: getters.getCurrentCourse._id,
        campaignId: getters.selectedChapterId,
        codeLanguage: state.selectedLanguage
      })
    },

    getContentDescription (_state, getters, _rootState, _rootGetters) {
      return (moduleNum, contentId) => {
        const modules = getters.getModuleInfo
        const moduleContent = modules[moduleNum] || []

        const content = moduleContent.find(({ _id }) => _id === contentId);
        if (!content) {
          return ''
        }
        return content?.description || (content?.documentation?.specificArticles || []).find(({name}) => name === 'Learning Goals')?.body || ''
      }
    },

    getSelectedLanguage (state, language) {
      return state.selectedLanguage
    }
  },

  actions: {
    toggleCurriculumGuide ({ state, commit, rootGetters, dispatch }) {
      if (state.visible) {
        commit('closeCurriculumGuide')
      } else {
        if (!state.selectedCampaignId) {
          const sortedCourses = rootGetters['courses/sorted'] || []
          if (sortedCourses[0]) {
            // Ensure that the first course is automatically selected
            dispatch('setSelectedCampaign', sortedCourses[0].campaignID)
          }
        }
        commit('openCurriculumGuide')
      }
    },

    setSelectedCampaign ({ state, commit }, campaignID) {
      commit('setSelectedCampaignId', campaignID)
    }
  }
}
