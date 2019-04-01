import classroomsApi from 'core/api/classrooms'

export default {
  namespaced: true,

  state: {
    loading: {
      classrooms: false
    },

    classrooms: {
      active: [],
      archived: []
    }
  },

  mutations: {
    toggleLoading: (state, key) => state.loading[key] = !state.loading[key],

    addClassrooms: (state, classrooms) => {
      const classroomsState = {
        active: [],
        archived: []
      }

      classrooms.forEach((classroom) => {
        if (classroom.archived) {
          classroomsState.archived.push(classroom)
        } else {
          classroomsState.active.push(classroom)
        }
      })

      state.classrooms = classroomsState
    }
  },

  actions: {
    fetchClassroomsForTeacher: ({ commit }, teacherId) => {
      commit('toggleLoading', 'classrooms')

      return classroomsApi.fetchByOwner(teacherId)
        .then(res =>  {
          if (res) {
            commit('addClassrooms', res)
          } else {
            throw new Error('Unexpected response from fetch classrooms API.')
          }
        })
        .catch((e) => console.error('Fetch classrooms failure', e)) // TODO handle this
        .finally(() => commit('toggleLoading', 'classrooms'))
    },
  }
}

