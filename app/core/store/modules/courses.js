// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const api = require('core/api')
const { sortCourses, sortOtherCourses } = require('core/utils')

// This module should eventually include things such as: session, player code, score, thangs, etc
module.exports = {
  namespaced: true,

  state: {
    loaded: false,
    loadedOther: false,
    byId: {},
    otherById: {}
  },

  getters: {
    sorted (state) {
      const courses = _.values(state.byId)
      return sortCourses(courses)
    },
    sortedAll (state) {
      const courses = _.values(state.byId)
      const otherCourses = _.values(state.otherById)
      return [...sortCourses(courses), ...sortOtherCourses(otherCourses)]
    },
  },

  mutations: {
    // TODO this doesn't handle removed courses (unlikely to occur - but would this be simpler if we built an object by id from response and swapped it out
    addCourses (state, courses) {
      courses.forEach(c => Vue.set(state.byId, c._id, c))
      state.loaded = true
    },
    addOtherCourses (state, courses) {
      courses.forEach(c => Vue.set(state.otherById, c._id, c))
      state.loadedOther = true
    }
  },

  actions: {
    fetch ({ commit, state }) {
      if (state.loaded) { return Promise.resolve() }
      return api.courses.getAll().then(courses => commit('addCourses', courses))
    },

    fetchOther ({ commit, state }, other) {
      if (state.loadedOther) { return Promise.resolve() }
      return api.courses.getAll({}, other).then(courses => commit('addOtherCourses', courses))
    },

    fetchReleased ({ commit, state }, options) {
      if (options == null) { options = {} }
      if (state.loaded) { return Promise.resolve() }
      return api.courses.getReleased(options).then(courses => commit('addCourses', courses))
    }
  }
}
