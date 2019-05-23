/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import levelSchema from 'schemas/models/level'
import store from 'app/core/store'
import api from 'core/api'
import utils from 'core/ozariaUtils'

// TODO: Be explicit about the properties being stored
const emptyLevel = _.zipObject((Array.from(_.keys(levelSchema.properties)).map((key) => [key, null])))

// This module should eventually include things such as: session, player code, score, thangs, etc
export default {
  namespaced: true,

  state: {
    initializing: false,

    classroom: undefined,
    classroomCourseLevelData: undefined,
    courseInstance: undefined,
    campaignData: undefined,
    levelSessionsForUser: undefined,

    level: emptyLevel,
    hintsVisible: false,
    timesCodeRun: 0,
    timesAutocompleteUsed: 0,
    playing: false
  },

  mutations: {
    setPlaying (state, playing) {
      state.playing = playing
    },

    setLevel (state, level) {
      state.level = Object.assign({}, level)
    },

    setHintsVisible (state, visible) {
      state.hintsVisible = visible
    },

    incrementTimesCodeRun (state) {
      state.timesCodeRun += 1
    },

    setTimesCodeRun (state, times) {
      state.timesCodeRun = times
    },

    incrementTimesAutocompleteUsed (state) {
      state.timesAutocompleteUsed += 1
    },

    setTimesAutocompleteUsed (state, times) {
      state.timesAutocompleteUsed = times
    },

    toggleInitializing (state) {
      state.initializing = !state.initializing
    },

    initializeGame (state, { classroom, courseInstance, levelSessionsForUser, campaignData, classroomCourseLevelData }) {
      state.classroom = classroom
      state.classroomCourseLevelData = classroomCourseLevelData
      state.courseInstance = courseInstance
      state.levelSessionsForUser = levelSessionsForUser
      state.campaignData = campaignData
    }
  },

  actions: {
    async initForCampaign ({ commit, dispatch, state, rootState }, campaignHandle) {
      if (state.initializing) {
        throw new Error('Initialization started')
      }

      // TODO handle existing game state - cleanup?
      try {
        commit('toggleInitializing')

        const userId = rootState.me._id.toString()

        const levelSessionsPromise = dispatch('levelSessions/fetchByUserId', userId, { root: true })
        const campaignDataPromise = dispatch('campaigns/fetchByHandle', campaignHandle, { root: true })

        const levelSessions = await levelSessionsPromise
        const campaignData = await campaignDataPromise

        commit('initializeGame', {
          levelSessions,
          campaignData
        })
      } catch (e) {
        // TODO handle
      } finally {
        commit('toggleInitializing')
      }
    },

    async initForCourseInstanceAndCampaign ({ commit, dispatch, state, rootState }, courseInstanceId, campaignHandle) {
      if (state.initializing) {
        throw new Error('Initialization started')
      }

      // TODO handle existing game state - cleanup?
      try {
        commit('toggleInitializing')

        const userId = rootState.me._id.toString()

        const levelSessionsPromise = dispatch('levelSessions/fetchByUserId', userId, { root: true })
        const campaignDataPromise = dispatch('campaigns/fetchByHandle', campaignHandle, { root: true })

        const courseInstance = await dispatch('courseInstances/fetchById', courseInstanceId, { root: true })

        // TODO integrate this with store
        const classroomCourseLevelsDataPromise = await api.classrooms.getCourseLevels({
          classroomID: courseInstanceId.classroomID,
          courseID: courseInstanceId.courseID
        })

        const classroom = await dispatch('classrooms/fetchClassroomForId', courseInstance.classroomID, { root: true })

        const levelSessions = await levelSessionsPromise
        const campaignData = await campaignDataPromise
        const classroomCourseLevelData = await classroomCourseLevelsDataPromise

        commit('initializeGame', {
          levelSessions,
          campaignData,
          classroom,
          courseInstance,
          classroomCourseLevelData
        })
      } catch (e) {
        // TODO handle
      } finally {
        commit('toggleInitializing')
      }
    }
  },

  // TODO review usages of state
  getters: {
    getClassroomCourse (state) {
      const classroom = state.classroom || {}
      const classroomCourses = classroom.courses || []

      return classroomCourses.find(course => course._id === state.courseInstance.courseID)
    },

    campaignLevels (state) {
      const campaignData = state.campaignData || {}
      return campaignData.levels || []
    },

    getClassroomLevelMap (state, getters) {
      const classroomCourseLevels = (getters.getClassroomCourse() || {}).levels || []
      const classroomLevelMap = {}

      for (const level of classroomCourseLevels) {
        classroomLevelMap[level.original] = level
      }

      return classroomLevelMap
    },

    courseLevels (state, getters) {
      const existingCampaignLevels = getters.campaignLevels
      const classroomLevelMap = getters.getClassroomLevelMap()

      const courseLevelsData = {}
      for (const level of state.classroomCourseLevelData || []) {
        const levelOriginal = level.original
        if (existingCampaignLevels[levelOriginal]) {
          courseLevelsData[levelOriginal] = existingCampaignLevels[levelOriginal]
        } else {
          courseLevelsData[levelOriginal] = level
        }

        if (classroomLevelMap[levelOriginal].position) {
          courseLevelsData[levelOriginal].position = classroomLevelMap[levelOriginal].position
        }

        if (classroomLevelMap[levelOriginal].nextLevels) {
          courseLevelsData[levelOriginal].nextLevels = classroomLevelMap[levelOriginal].nextLevels
        }

        if (classroomLevelMap[levelOriginal].first) {
          courseLevelsData[levelOriginal].first = classroomLevelMap[levelOriginal].first
        }
      }

      return courseLevelsData
    },

    levels (state, getters) {
      if (state.courseInstance) {
        return getters.courseLevels
      }

      return getters.campaignLevels
    },

    getLevelStatusMap (state, getters) {
      // Remove the level sessions for the levels played in another language - for the classroom version of unit map
      let levelSessions = state.levelSessions || []

      // TODO should this use classroom level map or the level map returned from getLevels
      if (state.classroom) {
        const classroomLevelMap = getters.getClassroomLevelMap() || {}
        levelSessions = levelSessions.filter((session) => {
          const classroomLevel = classroomLevelMap[session.level.original]
          if (!classroomLevel) {
            return true
          }

          const expectedLanguage = classroomLevel.primerLanguage || state.classroom.aceConfig.language
          if (session.codeLanguage !== expectedLanguage) {
            return false
          }

          return true
        })
      }

      return utils.getLevelStatusMap(levelSessions)
    }
  },

  getNextLevels (state, getters) {
    const campaignData = state.campaignData || {}

    if (state.courseInstance || campaignData.type === 'course') {
      return utils.findNextLevelsBySession(this.levelSessions, this.levels, this.levelStatusMap)
    } else {
      // TODO what do we do if not course instance?
    }
  },

  isLevelNext (state, getters) {
    return (levelOriginal) => {
      if (getters.getNextLevels().includes(levelOriginal)) {
        return true
      }
    }
  },

  isLevelUnlocked (state, getters) {
    return (levelOriginal) => {
      if (getters.isLevelNext(levelOriginal) || getters.getLevels()[levelOriginal].first) {
        return true
      }

      const levelStatusMap = getters.getLevelStatusMap() || {}
      const levelStatus = levelStatusMap[levelOriginal]

      if (levelStatus) {
        return levelStatus === 'started' || levelStatus === 'complete'
      }

      throw new Error('Level not found')
    }
  }
}

Backbone.Mediator.subscribe('level:set-playing', function (e) {
  let left
  const playing = (left = (e != null ? e : {}).playing) != null ? left : true

  return store.commit('game/setPlaying', playing)
})
