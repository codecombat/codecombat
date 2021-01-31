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
    isInGodMode (state) {
      return ((state || {}).permissions || []).indexOf('godmode') > -1
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

    forumLink (state) {
      let link = 'http://discourse.codecombat.com/'
      const lang = (state.preferredLanguage || 'en-US').split('-')[0]
      if (['zh', 'ru', 'es', 'fr', 'pt', 'de', 'nl', 'lt'].includes(lang)) {
        link += `c/other-languages/${lang}`
      }
      return link
    },

    isAdmin (state) {
      const permissions = state.permissions || []
      return permissions.indexOf('admin') > -1
    },

    isLicensor (state) {
      return ((state != null ? state.permissions : undefined) || []).indexOf('licensor') > -1
    },

    isSchoolAdmin (state) {
      return ((state != null ? state.permissions : undefined) || []).indexOf('schoolAdministrator') > -1
    },

    preferredLocale (state) {
      return state.preferredLanguage || 'en-US'
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

    authenticated ({ commit }, user) {
      commit('updateUser', user)
    }
  }
}
