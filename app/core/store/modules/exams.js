import { postExam, getExamById } from '../../api/exams'
import { startExam, submitExam, getUserExam } from '../../api/user-exams'

export default {
  namespaced: true,
  state: {
    examsById: {},
    userExam: null,
  },
  mutations: {
    addExam (state, exam) {
      state.examsById[exam._id] = exam
    },
    updateUserExam (state, { examId, userExam }) {
      // for easy tracking userExam updates,
      // we only store the latest user exam
      // we will fetch it every time open an exam page so won't be messed up
      state.userExam = userExam
    },
  },
  actions: {
    async createExam ({ commit }, exam) {
      const response = await postExam(exam)
      commit('addExam', response)
    },
    async fetchExamById ({ commit, state }, id) {
      const exam = await getExamById(id)
      commit('addExam', exam)
    },

    async startExam ({ commit }, { examId, codeLanguage, duration }) {
      const response = await startExam(examId, { codeLanguage, duration })
      commit('updateUserExam', {
        examId,
        userExam: response,
      })
    },

    async submitExam ({ commit }, { userExamId, expires }) {
      const response = await submitExam(userExamId, {
        expires,
      })
      commit('updateUserExam', {
        examId: response.examId,
        userExam: response,
      })
    },

    async fetchUserExam ({ commit }, { examId, includeArchived = false }) {
      try {
        const response = await getUserExam(examId, includeArchived)
        commit('updateUserExam', {
          examId,
          userExam: response,
        })
      } catch (e) {
        console.log(e)
      }
    },
  },
  getters: {
    getExamById: (state) => (id) => {
      return state.examsById[id]
    },
    userExam: (state) => {
      return state.userExam
    },
  },
}
