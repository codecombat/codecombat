import classroomsApi from 'core/api/classrooms'
import usersApi from 'core/api/users'
import User from 'models/User'

export default {
  namespaced: true,

  state: {
    loading: {
      teacher: false,
      classrooms: false,
      teachers: false
    },

    teacher: undefined,

    isSchoolAdministrator: false,
    administratedTeachers: [],

    teacherClassrooms: []
  },

  mutations: {
    toggleLoading: (state, key) => state.loading[key] = !state.loading[key],

    setTeacher: (state, teacher) => state.teacher = teacher,

    addTeachers: (state, teachers) => {
      state.administratedTeachers = teachers;
    },

    addClassrooms: (state, classrooms) => {
      state.teacherClassrooms = classrooms;
    }
  },

  actions: {
    fetchTeachers: ({ commit, rootState }) => {
      commit('toggleLoading', 'teachers')

      return usersApi
        .fetchByIds(rootState.me.administratedTeachers || [])
        .then(res =>  {
          if (res) {
            commit('addTeachers', res)
          } else {
            throw new Error('Unexpected response from teachers by ID API.')
          }
        })
        .catch((e) => console.error('Fetch teachers failure', e)) // TODO handle this
        .finally(() => commit('toggleLoading', 'teachers'))
    },

    fetchTeacher: ({ commit, state }, id) => {
      commit('toggleLoading', 'teacher')


      let resultPromise;
      const teacher = state.administratedTeachers.find(t => t.id === id);

      if (teacher) {
        resultPromise = Promise.resolve(teacher);
      } else {
        resultPromise = usersApi
          .fetchByIds([ id ])
          .then(res =>  {
            if (res && res.length > 0) {
              commit('setTeacher', res[0])
            } else {
              throw new Error('Teacher not returned from API')
            }
          })
          .catch((e) => console.error('Fetch teachers failure', e)) // TODO handle this
      }

      return resultPromise
        .finally(() => commit('toggleLoading', 'teacher'))
    },

    fetchTeacherClassrooms: ({ commit }, id) => {
      commit('toggleLoading', 'classrooms')

      classroomsApi.fetchByOwner(id)
        .then((res) => {
          if (res) {
            commit('addClassrooms', res)
          } else {
            throw new Error('Unexpected response from classrooms API.')
          }
        })
        .catch((e) => console.error('Classrooms failure', e)) // TODO handle this
        .finally(() => commit('toggleLoading', 'classrooms'))
    }
  }
}

