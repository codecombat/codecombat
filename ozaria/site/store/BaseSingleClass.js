/**
 * This store tracks the student checkboxes.
 */

import { COMPONENT_NAMES } from 'ozaria/site/components/teacher-dashboard/common/constants.js'
// TODO: Ensure download size isn't too big.
const projectionData = {
  interactives: '_id,i18n,name,slug,displayName,interactiveType,unitCodeLanguage,documentation,draggableOrderingData,insertCodeData,draggableStatementCompletionData,defaultArtAsset,promptText',
  levelSessions: 'state.complete,state.goalStates,level,creator,changed,created,dateFirstCompleted,submitted,codeConcepts,code,codeLanguage,introContentSessionComplete,playtime',
  levels: 'original,name,description,slug,concepts,displayName,type,ozariaType,practice,shareable,i18n,assessment,goals,additionalGoals,documentation,thangs',
  users: 'firstName,lastName,name,email,coursePrepaid,coursePrepaidID,deleted'
}

export default {
  namespaced: true,
  state: {
    selectedStudents: {}
  },

  getters: {
    isStudentSelected: (state) => (studentId) => {
      return state.selectedStudents[studentId] || false
    },

    selectedStudentIds (state) {
      return Object.keys(state.selectedStudents || {})
    }
  },

  mutations: {
    setCheckedStudent (state, { studentId }) {
      if (state.selectedStudents[studentId]) {
        return
      }
      Vue.set(state.selectedStudents, studentId, true)
    },
    removeCheckedStudent (state, { studentId }) {
      Vue.delete(state.selectedStudents, studentId)
    },
    clearSelectedStudents (state) {
      state.selectedStudents = {}
    }
  },

  actions: {
    addStudentSelectedId ({ commit }, { studentId }) {
      commit('setCheckedStudent', { studentId })
    },

    removeStudentSelectedId ({ commit }, { studentId }) {
      commit('removeCheckedStudent', { studentId })
    },

    toggleStudentSelectedId ({ dispatch, state }, { studentId }) {
      if (state.selectedStudents[studentId]) {
        dispatch('removeStudentSelectedId', { studentId })
      } else {
        dispatch('addStudentSelectedId', { studentId })
      }
    },

    clearSelectedStudents ({ commit }) {
      commit('clearSelectedStudents')
    },

    fetchData ({ dispatch }) {
      dispatch('teacherDashboard/fetchData', { componentName: COMPONENT_NAMES.MY_CLASSES_SINGLE, options: { data: projectionData } }, { root: true })
    }
  }
}
