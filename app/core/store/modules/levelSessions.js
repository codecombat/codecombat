import levelSessionsApi from 'core/api/level-sessions'

const SESSIONS_PER_REQUEST = 10

export default {
  namespaced: true,

  state: {
    loading: {
      sessions: false,
    },

    levelSessions: []
  },

  mutations: {
    toggleLoading: (state, key) => state.loading[key] = !state.loading[key],

    setSessions: (state, sessions) => state.levelSessions = sessions
  },

  actions: {
    // TODO need to index this by classroom ID
    // TODO add a way to clear out old level session data
    fetchForClassroomMembers: ({ commit }, classroom) => {
      commit('toggleLoading', 'sessions')

      let requests = new Array[classroom.members.length / SESSIONS_PER_REQUEST + 1]
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

          commit('setSessions', sessions)
        })
        .catch((e) => console.error('Fetch level sessions failure', e)) // TODO handle this
        .finally(() => commit('toggleLoading', 'sessions'))
    },
  }
}
