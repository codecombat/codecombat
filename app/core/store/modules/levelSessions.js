import levelSessionsApi from 'core/api/level-sessions'

const SESSIONS_PER_REQUEST = 10

export default {
  namespaced: true,

  state: {
    loading: {
      sessionsByClassroom: {}
    },

    /*
     * Structure of level sessions state:
     *
     *  CLASSROOM_ID: {
     *    sessions: [],
     *    levelCompletionsByUser: {
     *       LEVEL_ID: true / false
     *     },
     *    levelSessionsMapByUser: {
     *      USER_ID: {
     *        LEVEL_ORIGINAL: {}
     *       } 
     *     }
     *  }
     */
    levelSessionsByClassroom: {},
    // level sessions for a campaign in any language depending on whats fetched from fetchLevelSessionsForCampaign
    levelSessionsByCampaign: {}
  },

  mutations: {
    toggleClassroomLoading: (state, classroomId) => {
      let loading = true;
      if (state.loading.sessionsByClassroom[classroomId]) {
        loading = false
      }

      Vue.set(state.loading.sessionsByClassroom, classroomId, loading)
    },

    initSessionsByClassroomState: (state, classroomId) => {
      if (state.levelSessionsByClassroom[classroomId]) {
        return
      }

      Vue.set(state.levelSessionsByClassroom, classroomId, {
        sessions: [],
        levelCompletionsByUser: {},
        levelSessionMapByUser: {}
      })
    },

    initSessionsByCampaignState: (state, campaign) => {
      if (state.levelSessionsByCampaign[campaign]) {
        return
      }

      Vue.set(state.levelSessionsByCampaign, campaign, {
        sessions: []
      })
    },

    setSessionsForClassroom: (state, { classroomId, sessions }) => {
      state.levelSessionsByClassroom[classroomId].sessions = sessions
      state.levelSessionsByClassroom[classroomId].levelCompletionsByUser = {}
      state.levelSessionsByClassroom[classroomId].levelSessionMapByUser = {}
    },

    addLevelCompletionsByUserForClassroom: (state, { classroomId, levelCompletionsByUser }) => {
      state.levelSessionsByClassroom[classroomId].levelCompletionsByUser = levelCompletionsByUser
    },

    addLevelSessionMapForClassroom: (state, { classroomId, levelSessionMapByUser }) => {
      state.levelSessionsByClassroom[classroomId].levelSessionMapByUser = levelSessionMapByUser
    },

    setSessionsForCampaign: (state, { campaign, sessions }) => {
      state.levelSessionsByCampaign[campaign].sessions = sessions
    }
  },
  getters: {
    getSessionsForCampaign: (state) => (campaign) => {
      return state.levelSessionsByCampaign[campaign]
    },
    getSessionsMapForClassroom: (state) => (classroom) => {
      return (state.levelSessionsByClassroom[classroom] || {}).levelSessionMapByUser
    }
  },
  // TODO add a way to clear out old level session data
  actions: {
    // TODO how do we handle two sets of parallel requests here? (ie user vists page, hits back and then visits again quickly)
    fetchForClassroomMembers: ({ commit, dispatch }, { classroom, options = {} }) => {
      commit('toggleClassroomLoading', classroom._id)
      commit('initSessionsByClassroomState', classroom._id)

      // TODO comment what next line is doing
      let requests = Array.from(
        Array(parseInt(classroom.members.length / SESSIONS_PER_REQUEST, 10) + 1)
      )

      requests = requests.map((v, i) =>
        levelSessionsApi.fetchForClassroomMembers(classroom._id, {
          data: {
            memberLimit: SESSIONS_PER_REQUEST,
            memberSkip: i * SESSIONS_PER_REQUEST,
            project: options.project || 'state.complete,level,creator,changed,created,dateFirstCompleted,submitted,codeConcepts'
          }
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
            sessions: Object.freeze(sessions)
          })

          dispatch('computeLevelSessionMapForClassroom', classroom._id)
        })
        .catch((e) => noty({ text: 'Fetch level sessions failure' + e, type: 'error' }))
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
        const sessionState = session.state || {}

        levelCompletionsByUser[user] = levelCompletionsByUser[user] || {}
        levelCompletionsByUser[user][session.level.original] = (sessionState.complete === true)
      }

      commit('addLevelCompletionsByUserForClassroom', {
        classroomId,
        levelCompletionsByUser: Object.freeze(levelCompletionsByUser)
      })
    },

    computeLevelSessionMapForClassroom ({ commit, state }, classroomId) {
      if (!state.levelSessionsByClassroom[classroomId] || !state.levelSessionsByClassroom[classroomId].sessions) {
        throw new Error('Sessions not loaded')
      }

      const classroomSessions = _.sortBy(state.levelSessionsByClassroom[classroomId].sessions || [], (s) => (s || {}).changed);

      const levelSessionMapByUser = {} // levelsessions grouped by user and level.original

      for (const session of classroomSessions) {
        const user = session.creator
        const levelOriginal = (session.level || {}).original
        if (levelOriginal) {
          levelSessionMapByUser[user] = levelSessionMapByUser[user] || {}
          levelSessionMapByUser[user][levelOriginal] = session
        }
      }

      commit('addLevelSessionMapForClassroom', {
        classroomId,
        levelSessionMapByUser
      })
    },

    async fetchLevelSessionsForCampaign ({ commit }, { campaignHandle, options }) {
      commit('initSessionsByCampaignState', campaignHandle)

      try {
        const campaignSessions = await levelSessionsApi.fetchForCampaign(campaignHandle, options)
        commit('setSessionsForCampaign', { campaign: campaignHandle, sessions: campaignSessions })
        return campaignSessions
      } catch (e) {
        console.error('Error in fetching campaign sessions', e)
        noty({ text: 'Error in fetching campaign sessions', type: 'error', timeout: 1000 })
      }
    }
  }
}
