import levelsApi from 'core/api/levels'

export default {
  namespaced: true,

  state: {
    levelsByClassroom: {}
  },
  getters: {

    getLevelsForClassroom: (state) => (classroomId) => {
      return (state.levelsByClassroom[classroomId] || [])
    }
  },

  mutations: {
    setLevelsForClassroom: (state, { classroomId, levels }) => {
      state.levelsByClassroom[classroomId] = levels
    }
  },

  // TODO add a way to clear out old level session data
  actions: {
    // TODO how do we handle two sets of parallel requests here? (ie user vists page, hits back and then visits again quickly)
    fetchForClassroom: ({ commit, dispatch }, classroomId) => {
      const request = levelsApi.fetchForClassroom(classroomId, {
        data: {
          project: 'original,name,primaryConcepts,concepts,primerLanguage,practice,shareable,i18n,assessment,assessmentPlacement,slug,goals'
        }
      })

      return Promise.all([request])
        .then((results) => {
          let levels = []

          for (let i = 0; i < results.length; i++) {
            const res = results[i]
            if (res && Array.isArray(res)) {
              levels = levels.concat(res)
            } else {
              throw new Error('Unexpected response from levels call')
            }
          }

          commit('setLevelsForClassroom', {
            classroomId,
            levels: Object.freeze(levels)
          })
        })
        .catch((e) => noty({ text: 'Fetch levels failure' + e, type: 'error' }))
    }
  }
}
