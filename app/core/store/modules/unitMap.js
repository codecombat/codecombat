import api from 'core/api'
import _ from 'lodash'

export default {
  namespaced: true,
  state: {
    currentLevelsList: {}
  },

  mutations: {
    setCurrentLevelsList: (state, levels) => {
      state.currentLevelsList = levels
    }
  },

  getters: {
    getCurrentLevelsList: (state) => state.currentLevelsList
  },

  actions: {
    /**
      We have a campaign.levels list and a classroom.courses.levels list, and they are not always in sync.
      Hence to get the levels data for a course instance for the unit map, we get the data as follows:
      1. levels list from the classroom snapshot
      2. position, nextLevels, first, campaignPage from the classroom snapshot, if does not exist then from campaign snapshot
      4. any other data from the campaign snapshot, but if doesnt exist in campaign any more then use the data in classroom snapshot
      */
    buildLevelsData: async ({ commit, rootGetters, dispatch }, { campaignHandle, courseInstanceId, courseId, classroom }) => {
      await dispatch('campaigns/fetch', { campaignHandle, courseInstanceId, courseId }, { root: true })
      const campaignData = rootGetters['campaigns/getCampaignData']({ campaignHandle, courseInstanceId, courseId })

      let levels = {}
      if (!courseInstanceId) {
        levels = campaignData.levels
      } else {
        try {
          // TODO get courseInstance/classroom data from vuex store
          const courseInstance = await api.courseInstances.get({ courseInstanceID: courseInstanceId })
          const courseId = courseInstance.courseID
          const classroomId = courseInstance.classroomID

          // campaign snapshot of the levels
          const existingCampaignLevels = _.cloneDeep(campaignData.levels)

          // classroom snapshot of the levels for the course
          classroom = classroom || await api.classrooms.get({ classroomID: classroomId })
          const classroomCourseLevels = _.find(classroom.courses, { _id: courseId }).levels

          // get levels data for the levels in the classroom snapshot
          const classroomCourseLevelsData = await api.classrooms.getCourseLevels({ classroomID: classroomId, courseID: courseId })

          const classroomLevelMap = {}
          for (let level of classroomCourseLevels) {
            classroomLevelMap[level.original] = level
            // Default the campaignPage value as 1 in classroom levels for backward compatibility
            if (!classroomLevelMap[level.original].campaignPage) {
              classroomLevelMap[level.original].campaignPage = 1
            }
          }

          let courseLevelsData = {}
          for (let level of classroomCourseLevelsData) {
            let original = level.original
            if (existingCampaignLevels[original]) {
              courseLevelsData[original] = existingCampaignLevels[original]
            } else {
              // a level which has been removed from the campaign but is saved in the course
              courseLevelsData[original] = level
            }
            // carry over position, nextLevels, first, campaignPage property stored in classroom course, if there are any
            if (classroomLevelMap[original].position) {
              courseLevelsData[original].position = classroomLevelMap[original].position
            }
            if (classroomLevelMap[original].nextLevels) {
              courseLevelsData[original].nextLevels = classroomLevelMap[original].nextLevels
            }
            if (classroomLevelMap[original].first) {
              courseLevelsData[original].first = classroomLevelMap[original].first
            }
            if (classroomLevelMap[original].campaignPage) {
              courseLevelsData[original].campaignPage = classroomLevelMap[original].campaignPage
            }
          }

          levels = courseLevelsData
        } catch (err) {
          console.error('Error in building levels data', err)
          // TODO: handle_error_ozaria
        }
      }
      commit('setCurrentLevelsList', levels)
    }
  }
}
