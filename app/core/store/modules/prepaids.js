import prepaidsApi from 'core/api/prepaids'

export default {
  namespaced: true,

  state: {
    loading: {
      byTeacher: {}
    },

    prepaids: {
      byTeacher: {} // grouped by status - expired, pending, empty and available
    }
  },

  mutations: {
    toggleLoadingForTeacher: (state, teacherId) => {
      Vue.set(
        state.loading.byTeacher,
        teacherId,
        !state.loading.byTeacher[teacherId]
      )
    },

    addPrepaidsForTeacher: (state, { teacherId, prepaids }) => {
      const teacherPrepaids = {
        expired: [],
        pending: [],
        empty: [],
        available: []
      }
      prepaids.forEach((prepaid) => {
        if (prepaid.endDate && new Date(prepaid.endDate) < new Date()) {
          teacherPrepaids.expired.push(prepaid)
        } else if (prepaid.startDate && new Date(prepaid.startDate) > new Date()) {
          teacherPrepaids.pending.push(prepaid)
        } else if (prepaid.maxRedeemers - (prepaid.redeemers || []).length <= 0 || prepaid.maxRedeemers <= 0) {
          teacherPrepaids.empty.push(prepaid)
        } else {
          teacherPrepaids.available.push(prepaid)
        }
      })
      Vue.set(state.prepaids.byTeacher, teacherId, teacherPrepaids)
    }
  },

  getters: {
    getPrepaidsByTeacher: (state) => (id) => {
      return state.prepaids.byTeacher[id]
    }
  },

  actions: {
    // TODO: Does this also require using the `fetchMineAndShared` api call?
    fetchPrepaidsForTeacher: ({ commit }, teacherId) => {
      commit('toggleLoadingForTeacher', teacherId)

      return prepaidsApi.getByCreator(teacherId)
        .then(res => {
          if (res) {
            commit('addPrepaidsForTeacher', {
              teacherId,
              prepaids: res
            })
          } else {
            throw new Error('Unexpected response from fetch classrooms API.')
          }
        })
        .catch((e) => noty({ text: 'Fetch prepaids failure' + e, type: 'error', layout: 'topCenter', timeout: 2000 }))
        .finally(() => commit('toggleLoadingForTeacher', teacherId))
    }
  }
}
