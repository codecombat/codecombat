import _ from 'lodash'
const userSchema = require('schemas/models/user')
const api = require('core/api')
const utils = require('core/utils')

const emptyUser = _.zipObject((_.keys(userSchema.properties).map((key) => [key, null])))

export default {
  namespaced: true,
  state: _.cloneDeep(emptyUser),

  getters: {
    isAnonymous (state) { return state.anonymous === true },

    isStudent (state) {
      return (state != null ? state.role : undefined) === 'student'
    },

    isTeacher (state) {
      return (state != null ? state.role : undefined) === 'teacher'
    },

    isParent (state) {
      return (state != null ? state.role : undefined) === 'parent'
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

    set1fhAvatar ({ state, commit }, { levelThangTypeId, cinematicThangTypeId }) {
      if (!(levelThangTypeId && cinematicThangTypeId)) {
        throw new Error('Require both a levelThangTypeId and cinematicThangTypeId')
      }

      const ozariaConfig = state.ozariaUserOptions || {}
      commit('updateUser', { ozariaUserOptions:
        { ...ozariaConfig, avatar: { levelThangTypeId, cinematicThangTypeId } }
      })
    },

    authenticated ({ commit }, user) {
      commit('updateUser', user)
    }
  }
}
