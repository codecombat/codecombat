import _ from 'lodash'
const userSchema = require('schemas/models/user')
const api = require('core/api')

const emptyUser = _.zipObject((_.keys(userSchema.properties).map((key) => [key, null])))

export default {
  namespaced: true,
  state: emptyUser,
  getters: {
    currentUserId (state) {
      return state._id
    },

    isAnonymous (state) { return state.anonymous === true },

    isStudent (state) {
      return (state != null ? state.role : undefined) === 'student'
    },

    isTeacher (state) {
      return (state != null ? state.role : undefined) === 'teacher'
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
      return state.preferredLanguage
    },

    /**
     * @returns {object|undefined} avatar schema object or undefined if not defined.
     */
    getCh1Avatar (state) {
      return (state.ozariaUserOptions || {}).avatar
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
      commit('updateUser', { ozariaUserOptions:
        { ...ozariaConfig, avatar: { cinematicThangTypeId, cinematicPetThangId, avatarCodeString } }
      })
    }
  }
}
