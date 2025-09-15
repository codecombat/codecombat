import prepaidsApi from 'core/api/prepaids'
import usersApi from 'core/api/users'

const Prepaid = require('models/Prepaid')
const User = require('models/User')
const Bluebird = require('bluebird')

export default {
  namespaced: true,

  state: {
    loading: {
      byTeacher: {},
    },

    prepaids: {
      byTeacher: {}, // grouped by status - expired, pending, empty and available
    },

    joiners: { // users in the shared pool of a prepaid
      byPrepaid: {},
    },

    fetchedPrepaids: {},
  },

  mutations: {
    setFetchedPrepaidsForTeacher: (state, teacherId) => {
      Vue.set(state.fetchedPrepaids, teacherId, true)
    },

    toggleLoadingForTeacher: (state, teacherId) => {
      Vue.set(
        state.loading.byTeacher,
        teacherId,
        !state.loading.byTeacher[teacherId],
      )
    },

    addTestLicenseToTeacher: (state, { teacherId, prepaid }) => {
      const teacherPrepaids = state.prepaids.byTeacher[teacherId] || {
        expired: [],
        pending: [],
        empty: [],
        available: [],
        testOnlyAvaliable: [],
        testOnlyExpired: [],
      }
      teacherPrepaids.testOnlyAvaliable.push(prepaid)
      Vue.set(state.prepaids.byTeacher, teacherId, teacherPrepaids)
    },

    addPrepaidsForTeacher: (state, { teacherId, prepaids }) => {
      const teacherPrepaids = {
        expired: [],
        pending: [],
        empty: [],
        available: [],
        testOnlyAvaliable: [],
        testOnlyExpired: [],
      }
      prepaids.forEach((prepaid) => {
        if (prepaid.properties?.testStudentOnly) {
          if (prepaid.endDate && new Date(prepaid.endDate) < new Date()) {
            teacherPrepaids.testOnlyExpired.push(prepaid)
          } else {
            teacherPrepaids.testOnlyAvaliable.push(prepaid)
          }
        } else if (prepaid.endDate && new Date(prepaid.endDate) < new Date()) {
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
        email: joiner.email,
      })
      Vue.set(state.joiners.byPrepaid, prepaidId, joiners)
    },

    updateJoinerForPrepaid: (state, { prepaid, userID, maxRedeemers }) => {
      const prepaidID = prepaid._id
      const joiners = state.joiners.byPrepaid[prepaidID] || []
      joiners.forEach(j => {
        if (j._id === userID) {
          j.maxRedeemers = maxRedeemers
          if ((maxRedeemers <= 0) || (maxRedeemers >= prepaid.maxRedeemers)) {
            delete j.maxRedeemers
          }
        }
      })
      Vue.set(state.joiners.byPrepaid, prepaidID, joiners)
    },

    revokeJoiner: (state, { prepaidId, joiner }) => {
      const joiners = state.joiners.byPrepaid[prepaidId] || []
      const joinersWithoutJoiner = joiners.filter(item => item._id !== joiner._id)
      Vue.set(state.joiners.byPrepaid, prepaidId, joinersWithoutJoiner)
    },
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
      active = active.concat(prepaids.available).concat(prepaids.empty).concat(prepaids.pending).concat(prepaids.testOnlyAvaliable)
      return active
    },

    getExpiredLicensesForTeacher: (_state, getters) => (id) => {
      const prepaids = getters.getPrepaidsByTeacher(id)
      if (!prepaids) {
        return []
      }
      let expired = []
      expired = expired.concat(prepaids.expired).concat(prepaids.testOnlyExpired)
      return expired
    },

    getJoinersForPrepaid: (state) => (id) => {
      return state.joiners.byPrepaid[id] || []
    },

    getPossiblePrepaidFetchStates: (state) => {
      return {
        NOT_START: 'not start',
        FETCHING: 'fetching',
        FETCHED: 'fetched',
      }
    },

    getCurrentFetchStateForPrepaid: (state, getters) => (id) => {
      if (!state.fetchedPrepaids[id]) {
        return getters.getPossiblePrepaidFetchStates.NOT_START
      } else if (state.loading.byTeacher[id]) {
        return getters.getPossiblePrepaidFetchStates.FETCHING
      } else {
        return getters.getPossiblePrepaidFetchStates.FETCHED
      }
    },
  },

  actions: {
    ensurePrepaidsLoadedForTeacher: async ({ state, commit, dispatch }, teacherId) => {
      if (!state.prepaids.byTeacher[teacherId] && !state.fetchedPrepaids[teacherId]) {
        await dispatch('fetchPrepaidsForTeacher', { teacherId })
      }
    },

    fetchPrepaidsForTeacher: ({ state, commit }, { teacherId, sharedClassroomId, includeShared = true } = {}) => {
      if (state.fetchedPrepaids[teacherId] && state.loading.byTeacher[teacherId]) {
        // do not fetch twice at the same time
        return
      }
      commit('toggleLoadingForTeacher', teacherId)
      commit('setFetchedPrepaidsForTeacher', teacherId)

      const data = { sharedClassroomId }
      if (includeShared) {
        data.includeShared = true // so that we can pass correct false to server
      }
      // Fetch teacher's prepaids and shared prepaids.
      return prepaidsApi.getByCreator(teacherId, { data })
        .then(res => {
          if (res) {
            commit('addPrepaidsForTeacher', {
              teacherId,
              prepaids: res,
            })
          } else {
            throw new Error('Unexpected response from fetch classrooms API.')
          }
        })
        .catch((e) => noty({ text: 'Fetch prepaids failure' + e, type: 'error', layout: 'topCenter', timeout: 2000 }))
        .finally(() => commit('toggleLoadingForTeacher', teacherId))
    },
    fetchPrepaidsForAPIClient: ({ commit }, { clientId, teacherId }) => {
      commit('toggleLoadingForTeacher', teacherId)
      return prepaidsApi.getByClient(clientId)
        .then(res => {
          if (res) {
            commit('addPrepaidsForTeacher', {
              teacherId,
              prepaids: res,
            })
          } else {
            throw new Error('Unexpected response from fetch classrooms API.')
          }
        })
        .catch((e) => noty({ text: 'Fetch prepaids failure' + e, type: 'error', layout: 'topCenter', timeout: 2000 }))
        .finally(() => commit('toggleLoadingForTeacher', teacherId))
    },
    joinPrepaidByCodes: ({ commit }, options) => {
      return prepaidsApi.joinByCodes(options)
    },

    fetchJoinersForPrepaid: ({ commit }, prepaidId) => {
      return prepaidsApi.fetchJoiners({ prepaidID: prepaidId })
        .then(joiners => {
          if (joiners) {
            commit('setJoinersForPrepaid', {
              prepaidId,
              joiners,
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
                commit('addJoinerForPrepaid', { prepaidId, joiner: user })
              })
              .catch((e) => noty({ text: 'Error:' + e.message, type: 'error', layout: 'topCenter', timeout: 2000 }))
          }
        })
        .catch((e) => {
          console.error('Error in adding prepaid joiner:', e)
          throw e
        })
    },

    async revokeJoiner ({ commit }, { prepaidId, email }) {
      try {
        const user = await usersApi.getByEmail({ email })
        if (user) {
          try {
            await prepaidsApi.revokeJoiner({ prepaidID: prepaidId, userID: user._id })
            commit('revokeJoiner', { prepaidId, joiner: user })
          } catch (e) {
            noty({ text: 'Error:' + e.message, type: 'error', layout: 'topCenter', timeout: 2000 })
          }
        }
      } catch (e) {
        console.error('Error in revoking prepaid joiner:', e)
        throw e
      }
    },

    async applySpecificLicenses ({ getters }, { selectedId, members, teacherId, sharedClassroomId }) {
      const prepaids = getters.getPrepaidsByTeacher(teacherId)
      if (!prepaids) {
        throw new Error('no prepaids for the teacher')
      }
      const selectedPrepaid = prepaids.available.find(data => data._id === selectedId)
      if (!selectedPrepaid) {
        noty({ text: 'Something went wrong, selected license no longer available.', type: 'error' })
        return
      }
      const prepaid = new Prepaid(selectedPrepaid)
      const students = members.map(data => new User(data))
      const unenrolledStudents = students.filter(stu => {
        const p = prepaid.numericalCourses()
        const s = p & stu.prepaidNumericalCourses()
        return (p ^ s)
      })
      const availableSpots = prepaid.get('maxRedeemers') - (prepaid.get('members')?.length || 0)
      const canApplyLicenses = availableSpots >= unenrolledStudents.length
      const additionalLicensesNum = unenrolledStudents.length - availableSpots

      if (!canApplyLicenses) {
        // NOTE: Should we have specific UI noty side effects within the store logic?
        noty({
          text: $.i18n.t('teachers.need_more_license', { additionalLicensesNum }),
          layout: 'center',
          type: 'error',
          killer: true,
          timeout: 5000,
        })
        return
      }
      const numberEnrolled = unenrolledStudents.length
      if (numberEnrolled) {
        let confirmed = false
        // NOTE: Should we have specific UI noty side effects within the store logic?
        await new Promise((resolve) => noty({
          text: $.i18n.t('teachers.confirm_apply_license', {
            numberEnrolled,
            numberRemaining: availableSpots - unenrolledStudents.length,
          }),
          type: 'info',
          buttons: [
            {
              addClass: 'btn btn-primary',
              text: $.i18n.t('modal.okay'),
              onClick: function ($noty) {
                confirmed = true
                $noty.close()
                resolve()
              },
            },
            {
              addClass: 'btn btn-danger',
              text: $.i18n.t('modal.cancel'),
              onClick: function ($noty) {
                $noty.close()
                resolve()
              },
            },
          ],
        }))

        if (!confirmed) {
          return
        }
      }

      const requests = []

      for (const user of unenrolledStudents) {
        requests.push(prepaid.redeem(user.get('_id'), { data: { sharedClassroomId } }))
      }
      const results = await Promise.allSettled(requests)
      let fails = 0
      results.forEach((res, index) => {
        if (res.status === 'rejected') {
          console.error(`Redeem student-${unenrolledStudents[index].get('_id')} failed.`)
          fails += 1
        }
      })
      if (fails) {
        noty({ text: $.i18n.t('teachers.fail_get_license', { fails }), type: 'error' })
      }
    },

    async applyLicenses ({ getters }, { members, teacherId, sharedClassroomId }) {
      const prepaids = getters.getPrepaidsByTeacher(teacherId)
      if (!prepaids) {
        throw new Error('no prepaids for the teacher')
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
          text: $.i18n.t('teachers.need_more_license', { additionalLicensesNum }),
          layout: 'center',
          type: 'error',
          killer: true,
          timeout: 5000,
        })
        return
      }
      const numberEnrolled = unenrolledStudents.length
      if (numberEnrolled) {
        let confirmed = false
        // NOTE: Should we have specific UI noty side effects within the store logic?
        await new Promise((resolve) => noty({
          text: $.i18n.t('teachers.confirm_apply_license', {
            numberEnrolled,
            numberRemaining: totalAvailableSpots - unenrolledStudents.length,
          }),
          type: 'info',
          buttons: [
            {
              addClass: 'btn btn-primary',
              text: $.i18n.t('modal.okay'),
              onClick: function ($noty) {
                confirmed = true
                $noty.close()
                resolve()
              },
            },
            {
              addClass: 'btn btn-danger',
              text: $.i18n.t('modal.cancel'),
              onClick: function ($noty) {
                $noty.close()
                resolve()
              },
            },
          ],
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

    async revokeLicenses (_, { members, sharedClassroomId, confirmed = false, updateUserProducts = false }) {
      const students = members
        .map(data => data instanceof User ? data : new User(data))
        .filter(u => u.isEnrolled() && u.prepaidType() === 'course')

      const existsLicenseToRevoke = students.length > 0
      if (!existsLicenseToRevoke) {
        noty({ text: $.i18n.t('teachers.no_licenses_applied') })
        return
      }

      if (!confirmed) {
        await new Promise((resolve) => noty({
          text: $.i18n.t('teachers.revoke_license_tips'),
          buttons: [
            {
              addClass: 'btn btn-primary',
              text: $.i18n.t('modal.okay'),
              onClick: function ($noty) {
                confirmed = true
                $noty.close()
                resolve()
              },
            },
            {
              addClass: 'btn btn-danger',
              text: $.i18n.t('modal.cancel'),
              onClick: function ($noty) {
                $noty.close()
                resolve()
              },
            },
          ],
        }))

        if (!confirmed) {
          return
        }
      }

      for (const student of students) {
        const courseProducts = student.activeProducts('course')
        await Bluebird.map(courseProducts, async product => {
          const prepaid = new Prepaid({
            _id: product.prepaid,
            type: 'course',
          })
          await new Promise((resolve, reject) =>
            prepaid.revoke(student, {
              success: resolve,
              error: (_p, e) => {
                noty({ text: e?.responseJSON?.message || 'The revocation of the license failed', type: 'error' })
                return reject(e)
              },
              data: { sharedClassroomId },
            }),
          )

          if (updateUserProducts) {
            student.set(
              'products',
              (student.get('products') || []).map((p) => {
                if (p.prepaid === product.prepaid) {
                  p.endDate = new Date().toISOString()
                }
                return p
              }),
            )
          }
        })
      }
    },
    async getTestLicense ({ commit }, { teacherId }) {
      return prepaidsApi.getOrCreateTestLicense()
        .then(res => {
          if (res) {
            commit('addTestLicenseToTeacher', { teacherId, prepaid: res })
          }
        })
    },
    async setJoinerMaxRedeemers ({ commit }, { prepaid, userID, maxRedeemers }) {
      const prepaidID = prepaid._id
      return prepaidsApi.setJoinerMaxRedeemers({
        prepaidID, userID, maxRedeemers,
      }).then(() => {
        return commit('updateJoinerForPrepaid', {
          prepaid, userID, maxRedeemers,
        })
      }).catch(error => {
        noty({ text: error?.responseJSON?.message || 'The update of the joiner failed', type: 'error' })
      })
    },
  },
}
