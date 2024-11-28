import aiProjectsApi from 'core/api/ai_projects'

export default {
  namespaced: true,

  state: {
    loading: {
      aiProjectsByClassroom: {}
    },

    aiProjectsByClassroom: {},

  },

  mutations: {
    toggleClassroomLoading: (state, classroomId) => {
      let loading = true
      if (state.loading.aiProjectsByClassroom[classroomId]) {
        loading = false
      }

      Vue.set(state.loading.aiProjectsByClassroom, classroomId, loading)
    },

    initAiProjectsByClassroomState: (state, classroomId) => {
      if (state.aiProjectsByClassroom[classroomId]) {
        return
      }

      Vue.set(state.aiProjectsByClassroom, classroomId, {
        projects: [],
        aiProjectCompletionsByUser: {},
        aiProjectMapByUser: {}
      })
    },

    clearSessionsByClassroom: (state, classroomId) => {
      Vue.set(state.aiProjectsByClassroom, classroomId, null)
    },

    setAiProjectsForClassroom: (state, { classroomId, projects }) => {
      state.aiProjectsByClassroom[classroomId].projects = projects
      state.aiProjectsByClassroom[classroomId].aiProjectCompletionsByUser = {}
      state.aiProjectsByClassroom[classroomId].aiProjectMapByUser = {}
    },

    addLevelCompletionsByUserForClassroom: (state, { classroomId, aiProjectCompletionsByUser }) => {
      state.aiProjectsByClassroom[classroomId].aiProjectCompletionsByUser = aiProjectCompletionsByUser
    },

    addAiProjectMapForClassroom: (state, { classroomId, aiProjectMapByUser }) => {
      state.aiProjectsByClassroom[classroomId].aiProjectMapByUser = aiProjectMapByUser
    },
  },
  getters: {

    getAiProjectsMapForClassroom: (state) => (classroom) => {
      return (state.aiProjectsByClassroom[classroom] || {}).aiProjectMapByUser
    },
    getSessionsForClassroom: (state) => (classroom) => {
      return (state.aiProjectsByClassroom[classroom] || {}).projects
    },
  },
  actions: {
    fetchForClassroomMembers: async ({ commit, dispatch }, { classroom, options = {} }) => {
      commit('toggleClassroomLoading', classroom._id)
      commit('initAiProjectsByClassroomState', classroom._id)

      try {
        const projects = await aiProjectsApi.fetchForClassroomMembers(classroom._id)

        commit('setAiProjectsForClassroom', {
          classroomId: classroom._id,
          projects: Object.freeze(projects)
        })

        dispatch('computeAiProjectMapForClassroom', classroom._id)
      } catch (e) {
        console.log(e)
        noty({ text: `Fetch ai projects failure: ${e}`, type: 'error' })
      } finally {
        commit('toggleClassroomLoading', classroom._id)
      }
    },

    computeAiProjectCompletionByUserForClassroom ({ commit, state }, classroomId) {
      const classroomSessionsState = state.levelSessionsByClassroom[classroomId]
      if (!classroomSessionsState || !classroomSessionsState.sessions) {
        throw new Error('Sessions not loaded')
      }

      const levelCompletionsByUser = {} // hello
      for (const session of classroomSessionsState.sessions) {
        const user = session.creator
        const sessionState = session.state || {}

        levelCompletionsByUser[user] = levelCompletionsByUser[user] || {}
        levelCompletionsByUser[user][session.level.original] = (sessionState.complete === true)
      }

      commit('addLevelCompletionsByUserForClassroom', {
        classroomId,
        levelCompletionsByUser: Object.freeze(levelCompletionsByUser)
      })
    },

    computeAiProjectMapForClassroom ({ commit, state }, classroomId) {
      if (!state.aiProjectsByClassroom[classroomId] || !state.aiProjectsByClassroom[classroomId].projects) {
        throw new Error('Sessions not loaded')
      }

      const classroomProjects = _.sortBy(state.aiProjectsByClassroom[classroomId].projects || [], (s) => (s || {}).changed)

      const aiProjectMapByUser = {} // levelsessions grouped by user and level.original

      for (const project of classroomProjects) {
        const user = project.user
        const scenarioId = project.scenario
        if (scenarioId) {
          aiProjectMapByUser[user] = aiProjectMapByUser[user] || {}
          aiProjectMapByUser[user][scenarioId] = aiProjectMapByUser[user][scenarioId] || []
          aiProjectMapByUser[user][scenarioId].push(project)
        }
      }

      commit('addAiProjectMapForClassroom', {
        classroomId,
        aiProjectMapByUser
      })
    }
  }
}
