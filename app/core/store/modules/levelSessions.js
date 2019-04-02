import Vue from 'vue'
import levelSessionsApi from 'core/api/level-sessions'

const SESSIONS_PER_REQUEST = 10

export default {
  namespaced: true,

  state: {
    loading: {
      sessionsByClassroom: {}
    },

    // {
    //   sessions: [],
    //   levelCompletionsByUser: {
    //      LEVEL_ID: true / false
    //    }
    // }
    levelSessionsByClassroom: {}
  },

  mutations: {
    toggleClassroomLoading: (state, classroomId) => {
      let loading = true;
      if (state.loading.sessionsByClassroom[classroomId]) {
        loading = false
      }

      Vue.set(state.loading.sessionsByClassroom, classroomId, loading)
    },

    setSessionsForClassroom: (state, { classroomId, sessions }) => {
      const levelSessionsState = {
        sessions,
        levelCompletionsByUser: {}
      }

      Vue.set(state.levelSessionsByClassroom, classroomId, levelSessionsState)
    },

    addLevelCompletionsByUserForClassroom: (state, { classroomId, levelCompletionsByUser }) =>
      state.levelSessionsByClassroom[classroomId].levelCompletionsByUser = levelCompletionsByUser
  },

  // TODO add a way to clear out old level session data
  actions: {
    // TODO how do we handle two sets of parallel requests here? (ie user vists page, hits back and then visits again quickly)
    fetchForClassroomMembers: ({ commit }, classroom) => {
      commit('toggleClassroomLoading', classroom._id)

      // TODO comment what next line is doing
      let requests = Array.from(Array(classroom.members.length / SESSIONS_PER_REQUEST + 1))
      requests = requests.map((v, i) =>
        levelSessionsApi.fetchForClassroomMembers(classroom._id, {
          memberLimit: SESSIONS_PER_REQUEST,
          memberSkip: i * SESSIONS_PER_REQUEST,
          project: 'state.complete,level,creator,changed,created,dateFirstCompleted,submitted,codeConcepts'
        })
      )

      return Promise.all(requests)
        .then((results) => {
          let sessions = [];

          for (let i = 0; i < results.length; i++) {
            const res = results[i];
            if (res && Array.isArray(res)) {
              sessions = sessions.concat(res)
            } else {
              throw new Error('Unexpected response from level sessions call');
            }
          }

          commit('setSessionsForClassroom', {
            classroomId: classroom._id,
            sessions
          })
        })
        .catch((e) => console.error('Fetch level sessions failure', e)) // TODO handle this
        .finally(() => commit('toggleClassroomLoading', classroom._id))
    },

    computeLevelCompletionsByUserForClassroom ({ commit, state }, classroomId) {
      const classroomSessionsState = state.levelSessionsByClassroom[classroomId];
      if (!classroomSessionsState || !classroomSessionsState.sessions) {
        throw new Error('Sessions not loaded')
      }

      const levelCompletionsByUser = {};
      for (const session of classroomSessionsState.sessions) {
        const user = session.creator

        levelCompletionsByUser[user] = levelCompletionsByUser[user] || {}
        levelCompletionsByUser[user][session.level.origial] = (session.level.completed === true)

      }

      commit('addLevelCompletionsByUserForClassroom', {
        classroomId,
        levelCompletionsByUser
      })
    }
  }
}
