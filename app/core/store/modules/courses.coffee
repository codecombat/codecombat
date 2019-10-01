api = require('core/api')
{ sortCourses } = require('core/utils')

# This module should eventually include things such as: session, player code, score, thangs, etc
module.exports = {
  namespaced: true

  state: {
    loaded: false,
    byId: {}
  },

  getters: {
    sorted: (state) ->
      courses = _.values(state.byId)
      return sortCourses(courses)
  },

  mutations: {
    # TODO this doesn't handle removed courses (unlikely to occur - but would this be simpler if we built an object by id from response and swapped it out
    addCourses: (state, courses) ->
      courses.forEach((c) ->
        Vue.set(state.byId, c._id, c)
      )
      state.loaded = true
  },

  actions: {
    fetch: ({commit, state}) ->
      return Promise.resolve() if state.loaded
      return api.courses.getAll().then((courses) ->
        commit('addCourses', courses)
      )
  }
}
