import prepaidsApi from 'core/api/prepaids'
import usersApi from 'core/api/users'

const Prepaid = require('models/Prepaid')
const User = require('models/User')

export default {
  namespaced: true,

  state: {
    loading: {
      byTeacher: {}
    },

    prepaids: {
      byTeacher: {} // grouped by status - expired, pending, empty and available
    },

    joiners: { // users in the shared pool of a prepaid
      byPrepaid: {}
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
    },

    setJoinersForPrepaid: (state, { prepaidId, joiners }) => {
      Vue.set(state.joiners.byPrepaid, prepaidId, joiners)
    },

    addJoinerForPrepaid: (state, { prepaidId, joiner }) => {
      const joiners = state.joiners.byPrepaid[prepaidId] || []
      joiners.push({
        _id: joiner._id,
        firstName: joiner.firstName,
        lastName: joiner.lastName,
        email: joiner.email
      })
      Vue.set(state.joiners.byPrepaid, prepaidId, joiners)
    },

    revokeJoiner: (state, { prepaidId, joiner }) => {
      const joiners = state.joiners.byPrepaid[prepaidId] || []
      const joinersWithoutJoiner = joiners.filter(item => item._id !== joiner._id);
      Vue.set(state.joiners.byPrepaid, prepaidId, joinersWithoutJoiner)
    }
  },

  getters: {
    getPrepaidsByTeacher: (state) => (id) => {
      return state.prepaids.byTeacher[id]
    },

    getLicensesStatsByTeacher: (_state, getters) => (id) => {
      const prepaids = getters.getPrepaidsByTeacher(id)
      if (!prepaids) {
        return { totalAvailableSpots: 0, totalSpots: 0 }
      }
      const availablePrepaids = prepaids.available.map(data => new Prepaid(data))
      const totalAvailableSpots = availablePrepaids.reduce((acc, prepaid) => acc + prepaid.openSpots(), 0)
      const totalSpots = availablePrepaids.reduce((acc, prepaid) => acc + prepaid.totalSpots(), 0)
      return { totalAvailableSpots, totalSpots, usedLicenses: totalSpots - totalAvailableSpots }
    },

    getActiveLicensesForTeacher: (_state, getters) => (id) => {
      const prepaids = getters.getPrepaidsByTeacher(id)
      if (!prepaids) {
        return []
      }
      let active = []
      active = active.concat(prepaids.available).concat(prepaids.empty).concat(prepaids.pending)
      return active
    },

    getExpiredLicensesForTeacher: (_state, getters) => (id) => {
      const prepaids = getters.getPrepaidsByTeacher(id)
      if (!prepaids) {
        return []
      }
      return prepaids.expired
    },

    getJoinersForPrepaid: (state) => (id) => {
      return state.joiners.byPrepaid[id] || []
    }
  },

  actions: {
    fetchPrepaidsForTeacher: ({ commit }, { teacherId, sharedClassroomId }) => {
      commit('toggleLoadingForTeacher', teacherId)

      // Fetch teacher's prepaids and shared prepaids.
      return prepaidsApi.getByCreator(teacherId, { data: { includeShared: true, sharedClassroomId } })
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
    },

    fetchJoinersForPrepaid: ({ commit }, prepaidId) => {
      return prepaidsApi.fetchJoiners({ prepaidID: prepaidId })
        .then(joiners => {
          if (joiners) {
            commit('setJoinersForPrepaid', {
              prepaidId,
              joiners
            })
          } else {
            throw new Error('Unexpected response from fetch joiners API.')
          }
        })
        .catch((e) => console.error('Error in fetching prepaid joiners:', e))
    },

    addJoinerForPrepaid: ({ commit }, { prepaidId, email }) => {
      return usersApi.getByEmail({ email })
        .then(user => {
          if (user) {
            prepaidsApi.addJoiner({ prepaidID: prepaidId, userID: user._id })
              .then(() => {
                commit('addJoinerForPrepaid', { prepaidId: prepaidId, joiner: user })
              })
              .catch((e) => noty({ text: 'Error:' + e.message, type: 'error', layout: 'topCenter', timeout: 2000 }))
          }
        })
        .catch((e) => {
          console.error('Error in adding prepaid joiner:', e);
          throw e;
        })
    },

    async revokeJoiner ({ commit }, { prepaidId, email }) {
      try {
        const user = await usersApi.getByEmail({ email })
        if (user) {
          try {
            await prepaidsApi.revokeJoiner({ prepaidID: prepaidId, userID: user._id })
            commit('revokeJoiner', { prepaidId: prepaidId, joiner: user })
          } catch (e) {
            noty({ text: 'Error:' + e.message, type: 'error', layout: 'topCenter', timeout: 2000 })
          }
        }
      } catch (e) {
        console.error('Error in revoking prepaid joiner:', e)
        throw e
      }
    },

    async applyLicenses ({ getters }, { members, teacherId, sharedClassroomId }) {
      const prepaids = getters.getPrepaidsByTeacher(teacherId)
      if (!prepaids) {
        throw new Error(`no prepaids for the teacher`)
      }

      const students = members.map(data => new User(data))
      const availablePrepaids = prepaids.available.map(data => new Prepaid(data))

      const unenrolledStudents = students
        .filter(user => !user.isEnrolled())

      const { totalAvailableSpots } = getters.getLicensesStatsByTeacher(teacherId)

      const canApplyLicenses = totalAvailableSpots >= unenrolledStudents.length
      const additionalLicensesNum = unenrolledStudents.length - totalAvailableSpots

      if (!canApplyLicenses) {
        // NOTE: Should we have specific UI noty side effects within the store logic?
        noty({
          text: `Oops! It looks like you need ${additionalLicensesNum} more license${additionalLicensesNum > 1 ? 's' : ''}. Visit My Licenses to learn more!`,
          layout: 'center',
          type: 'error',
          killer: true,
          timeout: 5000
        })
        return
      }
      const numberEnrolled = unenrolledStudents.length
      if (numberEnrolled) {
        let confirmed = false
        // NOTE: Should we have specific UI noty side effects within the store logic?
        await new Promise((resolve) => noty({
          text: `Please confirm that you'd like to apply licenses to ${numberEnrolled} student(s). You will have ${totalAvailableSpots - unenrolledStudents.length} license(s) remaining.`,
          type: 'info',
          buttons: [
            {
              addClass: 'btn btn-primary',
              text: 'Ok',
              onClick: function ($noty) {
                confirmed = true
                $noty.close()
                resolve()
              }
            },
            {
              addClass: 'btn btn-danger',
              text: 'Cancel',
              onClick: function ($noty) {
                $noty.close()
                resolve()
              }
            }
          ]
        }))

        if (!confirmed) {
          return
        }
      }

      const requests = []

      for (const prepaid of availablePrepaids) {
        if (unenrolledStudents.length === 0) {
          // Finished enrolling students.
          break
        }
        if (!Math.min(unenrolledStudents.length, prepaid.openSpots()) > 0) {
          // Not able to assign to this prepaid.
          continue
        }

        const availableLicenses = Math.min(unenrolledStudents.length, prepaid.openSpots())
        for (let i = 0; i < availableLicenses; i++) {
          const user = unenrolledStudents.pop()
          requests.push(prepaid.redeem(user.get('_id'), { data: { sharedClassroomId } }))
        }
      }

      // TODO: Handle error
      await Promise.all(requests)
    },

    async revokeLicenses (_, { members, sharedClassroomId }) {
      const students = members.map(data => new User(data)).filter(u => u.isEnrolled())

      const existsLicenseToRevoke = students.length > 0
      if (!existsLicenseToRevoke) {
        noty({ text: `No licenses applied to selected student(s).` })
        return
      }

      let confirmed = false
      await new Promise((resolve) => noty({
        text: `Revoking a license will make it available to apply to other students. Students will no longer be able to access paid content, but their progress will be saved. Please confirm you'd like to proceed.`,
        buttons: [
          {
            addClass: 'btn btn-primary',
            text: 'Ok',
            onClick: function ($noty) {
              confirmed = true
              $noty.close()
              resolve()
            }
          },
          {
            addClass: 'btn btn-danger',
            text: 'Cancel',
            onClick: function ($noty) {
              $noty.close()
              resolve()
            }
          }
        ]
      }))

      if (!confirmed) {
        return
      }

      const promises = []
      for (const student of students) {
        const prepaid = student.makeCoursePrepaid()
        promises.push(new Promise((resolve, reject) =>
          prepaid.revoke(student, {
            success: resolve,
            error: () => {
              console.error(`Didn't revoke this license`)
              resolve()
            },
            data: { sharedClassroomId }
          })
        ))
      }

      // TODO: Handle error
      await Promise.all(promises)
    }
  }
}
