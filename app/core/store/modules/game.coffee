levelSchema = require('schemas/models/level')
api = require('core/api')

# TODO: Be explicit about the properties being stored
emptyLevel = _.zipObject(([key, null] for key in _.keys(levelSchema.properties)))

# This module should eventually include things such as: session, player code, score, thangs, etc
module.exports = {
  namespaced: true
  state: {
    level: emptyLevel
    hintsVisible: false
    timesCodeRun: 0
    timesAutocompleteUsed: 0
    playing: false
  }
  mutations: {
    setPlaying: (state, playing) ->
      state.playing = playing
    setLevel: (state, updates) ->
      state.level = $.extend(true, {}, updates)
    setHintsVisible: (state, visible) ->
      state.hintsVisible = visible
    incrementTimesCodeRun: (state) ->
      state.timesCodeRun += 1
    setTimesCodeRun: (state, times) ->
      state.timesCodeRun = times
    incrementTimesAutocompleteUsed: (state) ->
      state.timesAutocompleteUsed += 1
    setTimesAutocompleteUsed: (state, times) ->
      state.timesAutocompleteUsed = times
  }
}

Backbone.Mediator.subscribe('level:set-playing', (e) ->
  playing = (e ? {}).playing ? true
  application.store.commit('game/setPlaying', playing)
)
