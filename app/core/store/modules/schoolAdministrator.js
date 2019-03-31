import classroomsApi from 'core/api/classrooms'
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
    fetchTeachers: ({ commit }) => {
      commit('toggleLoading', 'teachers')

      setTimeout(() => {
        commit(
          'addTeachers',
          [
            new User({ _id: '5c99876f08583a0075d5dfc7', name: 'Teacher 1', email: 'teacher1@education.com', lastLogin: 'LAST_LOGIN' }),
            new User({ _id: '5c9ad6328199860076fc373d', name: 'Teacher 2', email: 'teacher2@education.com', lastLogin: 'LAST_LOGIN' }),
          ]
        )

        commit('toggleLoading', 'teachers')
      }, 1000)
    },

    fetchTeacher: ({ commit, state }, id) => {
      commit('toggleLoading', 'teacher')


      for (const teacher of state.administratedTeachers) {
        if (teacher.get('id')) {
          commit('setTeacher', teacher)
          break;
        }
      }

      commit('toggleLoading', 'teacher')
    },

    fetchTeacherClassrooms: ({ commit }, id) => {
      commit('toggleLoading', 'classrooms')

      classroomsApi.fetchByOwner(id)
        .then((res) => commit('addClassrooms', res.body))
        .catch((e) => console.error('Classrooms failure', e)) // TODO handle this
        .finally(() => commit('toggleLoading', 'classrooms'))
    }
  }
}

