import prepaidsApi from 'core/api/prepaids'

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
    }
  },

  actions: {
    fetchPrepaidsForTeacher: ({ commit }, teacherId) => {
      commit('toggleLoadingForTeacher', teacherId)

      // Fetch teacher's prepaids and shared prepaids.
      return prepaidsApi.getByCreator(teacherId, { data: { includeShared: true } })
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

    async applyLicenses ({ getters }, { members, teacherId }) {
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
        for (let i = 0; i < Math.min(unenrolledStudents.length, prepaid.openSpots()); i++) {
          const user = unenrolledStudents.pop()
          requests.push(prepaid.redeem(user.get('_id')))
        }
      }

      // TODO: Handle error
      await Promise.all(requests)
    },

    async revokeLicenses (_, { members }) {
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
            error: reject
          })
        ))
      }

      // TODO: Handle error
      await Promise.all(promises)
    }
  }
}
