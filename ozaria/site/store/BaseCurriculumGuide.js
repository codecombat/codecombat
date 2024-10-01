import urls from 'app/core/urls'
import utils from 'app/core/utils'

export default {
  namespaced: true,

  state: () => ({
    visible: false,
    selectedCampaignId: undefined,
    selectedLanguage: 'python',
    hasAccessViaSharedClass: false
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
    },
    setAccessViaSharedClass (state, access) {
      state.hasAccessViaSharedClass = access
    }
  },

  getters: {
    chapterNavBar (_state, _getters, _rootState, rootGetters) {
      const courses = rootGetters['courses/sorted'] || []
      return courses
    },

    isOnLockedCampaign (state, getters, _rootState, rootGetters) {
      const course = getters.getCurrentCourse
      const isPaidTeacher = rootGetters['me/isPaidTeacher']
      return !(course?.free || isPaidTeacher || state.hasAccessViaSharedClass)
    },

    selectedChapterId (state) { // TODO: chapter or campaign or course?
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
      return gameContent?.capstone || {}
    },

    getModuleInfo (_state, getters, _rootState, rootGetters) {
      const gameContent = rootGetters['gameContent/getContentForCampaign'](getters.selectedChapterId)
      return gameContent?.modules
    },

    getModuleIntroLevels (_state, getters, _rootState, rootGetters) {
      const gameContent = rootGetters['gameContent/getContentForCampaign'](getters.selectedChapterId)
      return gameContent?.introLevels
    },

    getCurrentModuleNames (_state, getters, _rootState, _rootGetters) {
      return moduleNum => {
        const course = getters.getCurrentCourse
        let moduleInfo = Object.values(course.modules || {}).find(({ number }) => number === moduleNum || number === parseInt(moduleNum))
        if (!moduleInfo && _.size(course.modules || {})) {
          // Just match indexes in order, since module might not be numbered 1, 2, 3, but rather A1, A2, B1. Zero-indexed vs. one-indexed moduleNum.
          moduleInfo = Object.values(course.modules)[parseInt(moduleNum) - 1]
        }
        return utils.i18n(moduleInfo || {}, 'name')
      }
    },

    // Returns either the module info from the course or an empty object.
    getCurrentModuleHeadingInfo (_state, getters, _rootState, _rootGetters) {
      return moduleNum => {
        const course = getters.getCurrentCourse
        let moduleInfo = Object.values(course.modules || {}).find(({ number }) => number === moduleNum || number === parseInt(moduleNum))
        if (!moduleInfo && _.size(course.modules || {})) {
          // Just match indexes in order, since module might not be numbered 1, 2, 3, but rather A1, A2, B1. Zero-indexed vs. one-indexed moduleNum.
          moduleInfo = Object.values(course.modules)[parseInt(moduleNum) - 1]
        }
        let lessonSlidesUrl = utils.i18n(moduleInfo || {}, 'lessonSlidesUrl')
        if (lessonSlidesUrl) {
          if (typeof lessonSlidesUrl === 'object') {
            lessonSlidesUrl = lessonSlidesUrl[_state?.selectedLanguage || 'javascript'] || lessonSlidesUrl.javascript
          }
          moduleInfo = _.cloneDeep(moduleInfo)
          moduleInfo.lessonSlidesUrl = lessonSlidesUrl
        }
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

    getContentDescription () {
      return (content) => {
        if (!content) {
          return ''
        }

        return utils.i18n((content?.documentation?.specificArticles || []).find(({ name }) => name === 'Learning Goals'), 'body') ||
          utils.i18n(content, 'description') ||
          ''
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

    setSelectedCampaign ({ state, commit, dispatch }, campaignID) {
      commit('setSelectedCampaignId', campaignID)
      dispatch('gameContent/fetchGameContentForCampaign', { campaignId: campaignID }, { root: true })
    },
    setAccessViaSharedClass ({ commit }, access) {
      commit('setAccessViaSharedClass', access)
    }
  }
}
