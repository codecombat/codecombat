import _ from 'lodash'
const userSchema = require('schemas/models/user')
const User = require('app/models/User')
const api = require('core/api')
const utils = require('core/utils')

const emptyUser = _.zipObject((_.keys(userSchema.properties).map((key) => [key, null])))

export default {
  namespaced: true,
  state: _.cloneDeep(emptyUser),

  getters: {
    currentUserId (state) {
      return state._id
    },

    isInGodMode (state) {
      return ((state || {}).permissions || []).indexOf(User.PERMISSIONS.GOD_MODE) > -1 || ((state || {}).permissions || []).indexOf(User.PERMISSIONS.ONLINE_TEACHER) > -1
    },

    isAnonymous (state) { return state.anonymous === true },

    isStudent (state) {
      return (state || {}).role === 'student'
    },

    isTeacher (state, includePossibleTeachers) {
      return User.isTeacher(state, includePossibleTeachers)
    },

    isParent (state) {
      return (state || {}).role === 'parent'
    },

    isHomePlayer (state) {
      return !(state || {}).role && state.anonymous === false
    },

    isAdmin (state) {
      const permissions = state.permissions || []
      return permissions.indexOf(User.PERMISSIONS.COCO_ADMIN) > -1
    },

    isLicensor (state) {
      return ((state != null ? state.permissions : undefined) || []).indexOf(User.PERMISSIONS.LICENSOR) > -1
    },

    isAPIClient (state) {
      return ((state != null ? state.permissions : undefined) || []).indexOf(User.PERMISSIONS.API_CLIENT) > -1
    },

    isSchoolAdmin (state) {
      return ((state != null ? state.permissions : undefined) || []).indexOf(User.PERMISSIONS.SCHOOL_ADMINISTRATOR) > -1
    },

    preferredLocale (state) {
      return state.preferredLanguage || 'en-US'
    },

    isPaidTeacher (_state, _getters, _rootState, rootGetters) {
      const prepaids = rootGetters['prepaids/getPrepaidsByTeacher'](me.get('_id'))
      if (me.isPaidTeacher()) {
        return true
      }

      if (!prepaids) {
        return false
      }

      const { pending, empty, available } = prepaids
      if (pending.length + empty.length + available.length > 0) {
        return true
      }

      return me.isPremium()
    },

    /**
     * @returns {object|undefined} avatar schema object or undefined if not defined.
     */
    getCh1Avatar (state) {
      return (state.ozariaUserOptions || {}).avatar
    },

    inEU (state) {
      if (!state.country) {
        return undefined
      }

      return utils.inEU(state.country)
    },

    isSmokeTestUser (state) {
      return utils.isSmokeTestEmail(state.email)
    },

    hasSubscription (state) {
      if (state.payPal && state.payPal.billingAgreementID) {
        return true
      }

      if (state.stripe && (state.stripe.sponsorID || state.stripe.subscriptionID || state.stripe.free === true)) {
        return true
      }

      if (state.stripe && typeof state.stripe.free === 'string') {
        return new Date() < new Date(state.stripe.free)
      }

      return false
    },

    isPremium (state, getters) {
      return getters.isAdmin || getters.hasSubscription || getters.isInGodMode
    }
  },

  mutations: {
    updateUser (state, updates) {
      // deep copy, since nested data may be changed, and vuex store restricts mutations
      return _.assign(state, $.extend(true, {}, updates))
    }
  },

  actions: {
    save ({ state }, updates) {
      // updates this module, Backbone me, and server
      const user = _.assign({}, state, updates)
      return api.users.put(user)
        .then(() => {
          me.set(updates) // will also call updateUser
          return state
        })
    },

    setCh1Avatar ({ state, commit }, { cinematicThangTypeId, cinematicPetThangId, avatarCodeString }) {
      if (!(cinematicThangTypeId && cinematicPetThangId && avatarCodeString)) {
        throw new Error('Require a cinematicThangTypeId, cinematicPetThangId, and avatarCodeString')
      }

      const ozariaConfig = state.ozariaUserOptions || {}
      commit('updateUser', {
        ozariaUserOptions:
        { ...ozariaConfig, avatar: { cinematicThangTypeId, cinematicPetThangId, avatarCodeString } }
      })
    },

    authenticated ({ commit }, user) {
      commit('updateUser', user)
    }
  }
}
