import { getInteractive, getSession, fetchInteractiveSessionForAllClassroomMembers } from 'ozaria/site/api/interactive'

export default {
  namespaced: true,

  state: {
    loading: {
      interactive: false,
      session: false,
      byClassroom: {}
    },

    interactive: undefined,
    interactiveSession: undefined,

    /*
     * Structure of interactives by classroom session state:
     *
     *  CLASSROOM_ID: {
     *    sessions: [],
     *    interactiveSessionMapByUser: {
     *      USER_ID: {
     *        INTERACTIVE_ID: {}
     *       }
     *     }
     *  }
     */
    interactiveSessionsByClassroom: {}
  },

  mutations: {
    toggleInteractiveLoading (state) {
      state.loading.interactive = !state.loading.interactive
    },

    toggleInteractiveSessionLoading (state) {
      state.loading.session = !state.loading.session
    },

    toggleLoadingForClassroom: (state, classroomId) => {
      let loading = true
      if (state.loading.byClassroom[classroomId]) {
        loading = false
      }

      Vue.set(state.loading.byClassroom, classroomId, loading)
    },

    addInteractive (state, interactive) {
      state.interactive = interactive
    },

    addInteractiveSession (state, interactiveSession) {
      state.interactiveSession = interactiveSession
    },

    addInteractiveSessionsForClassroom (state, { classroomId, sessions }) {
      Vue.set(state.interactiveSessionsByClassroom[classroomId], `sessions`, sessions)
    },

    initSessionsByClassroomState: (state, classroomId) => {
      if (state.interactiveSessionsByClassroom[classroomId]) {
        return
      }

      Vue.set(state.interactiveSessionsByClassroom, classroomId, {
        sessions: [],
        interactiveSessionMapByUser: {}
      })
    },

    addInteractiveSessionMapForClassroom: (state, { classroomId, interactiveSessionMapByUser }) => {
      Vue.set(state.interactiveSessionsByClassroom[classroomId], 'interactiveSessionMapByUser', interactiveSessionMapByUser)
    },
  },

  getters: {
    currentInteractiveDataLoading (state) {
      return state.loading.interactive || state.loading.session
    },

    currentInteractive (state) {
      return state.interactive
    },

    currentInteractiveSession (state) {
      return state.interactiveSession
    },

    correctSubmissionFromSession (state, getters) {
      const currentInteractiveSession = getters.currentInteractiveSession
      if (!currentInteractiveSession) {
        return undefined
      }

      const submissions = currentInteractiveSession.submissions || []
      for (const submission of submissions) {
        if (submission.correct) {
          return submission
        }
      }

      return undefined
    },

    getInteractiveSessionsForClass: (state) => classId => {
      return state.interactiveSessionsByClassroom[classId]?.interactiveSessionMapByUser
    }

  },

  actions: {
    async loadInteractive ({ commit }, interactiveIdOrSlug) {
      commit('toggleInteractiveLoading')

      try {
        const interactive = await getInteractive(interactiveIdOrSlug)
        if (!interactive) {
          throw new Error('Invalid interactive received')
        }

        commit('addInteractive', interactive)
      } catch (e) {
        // TODO handle_error_ozaria
        throw new Error('Failed to load interactive')
      } finally {
        commit('toggleInteractiveLoading')
      }
    },

    async loadInteractiveSession ({ commit }, { interactiveIdOrSlug, sessionOptions }) {
      commit('toggleInteractiveSessionLoading')

      try {
        const interactiveSession = await getSession(interactiveIdOrSlug, sessionOptions)
        if (!interactiveSession) {
          throw new Error('Invalid interactive session received')
        }

        commit('addInteractiveSession', interactiveSession)
      } catch (e) {
        // TODO handle_error_ozaria
        throw new Error('Failed to load interactive session')
      } finally {
        commit('toggleInteractiveSessionLoading')
      }
    },

    async fetchSessionsForClassroomMembers ({ commit, dispatch }, classroom) {
      commit('toggleLoadingForClassroom', classroom._id)
      commit('initSessionsByClassroomState', classroom._id)
      try {
        const interactiveSessions = await Promise.all(fetchInteractiveSessionForAllClassroomMembers(classroom))
        if (!interactiveSessions) {
          throw new Error('Unexpected response returned from user API')
        }

        commit('addInteractiveSessionsForClassroom', {
          classroomId: classroom._id,
          sessions: Object.freeze(interactiveSessions.flat())
        })
        dispatch('computeInteractiveSessionMapForClassroom', classroom._id)
      } catch (e) {
        throw new Error('Failed to load interactive session:' + e)
      } finally {
        commit('toggleLoadingForClassroom', classroom._id)
      }
    },

    computeInteractiveSessionMapForClassroom ({ commit, state }, classroomId) {
      if (!state.interactiveSessionsByClassroom[classroomId] || !state.interactiveSessionsByClassroom[classroomId].sessions) {
        throw new Error('Sessions not loaded')
      }

      const interactiveSessionMapByUser = {} // interactive sessions grouped by user and interactive.interactiveId

      for (const session of state.interactiveSessionsByClassroom[classroomId].sessions) {
        const user = session.userId
        const interactiveId = session.interactiveId
        interactiveSessionMapByUser[user] = interactiveSessionMapByUser[user] || {}
        interactiveSessionMapByUser[user][interactiveId] = session
      }

      commit('addInteractiveSessionMapForClassroom', {
        classroomId,
        interactiveSessionMapByUser
      })
    }
  }
}
