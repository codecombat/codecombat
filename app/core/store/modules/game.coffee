levelSchema = require('schemas/models/level')
api = require('core/api')

# TODO: Be explicit about the properties being stored
emptyLevel = _.zipObject(([key, null] for key in _.keys(levelSchema.properties)))

# This module should eventually include things such as: session, player code, score, thangs, etc
module.exports = {
  namespaced: true
  state: {
    level: emptyLevel
  }
  mutations: {
    setLevel: (state, updates) ->
      state.level = $.extend(true, {}, updates)
  }
}
