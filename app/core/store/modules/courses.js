// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const api = require('core/api');
const { sortCourses } = require('core/utils');

// This module should eventually include things such as: session, player code, score, thangs, etc
module.exports = {
  namespaced: true,

  state: {
    loaded: false,
    byId: {}
  },

  getters: {
    sorted(state) {
      const courses = _.values(state.byId);
      return sortCourses(courses);
    }
  },

  mutations: {
    // TODO this doesn't handle removed courses (unlikely to occur - but would this be simpler if we built an object by id from response and swapped it out
    addCourses(state, courses) {
      courses.forEach(c => Vue.set(state.byId, c._id, c));
      return state.loaded = true;
    }
  },

  actions: {
    fetch({commit, state}) {
      if (state.loaded) { return Promise.resolve(); }
      return api.courses.getAll().then(courses => commit('addCourses', courses));
    },

    fetchReleased({commit, state}, options) {
      if (options == null) { options = {}; }
      if (state.loaded) { return Promise.resolve(); }
      return api.courses.getReleased(options).then(courses => commit('addCourses', courses));
    }
  }
};
