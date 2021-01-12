levelSchema = require('schemas/models/level')
api = require('core/api')
utils = require 'core/utils'

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
    levelSolution: {
    # Number of times state.levelSolution has been auto filled into the code editor.
      autoFilled: 0
      source: ''
    }
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
    setLevelSolution: (state, solution) ->
      state.levelSolution = solution
  }
  actions: {
    autoFillSolution: ({ commit, rootState }, codeLanguage) ->
      return unless hero = _.find (rootState.game.level?.thangs ? []), id: 'Hero Placeholder'
      return unless component = _.find(hero.components ? [], (c) -> c?.config?.programmableMethods?.plan)
      plan = component.config.programmableMethods.plan
      # This can live in Vuex at some point
      codeLanguage ?= utils.getQueryVariable('codeLanguage') ? 'javascript'
      return unless rawSource = plan.solutions?.find(
        (s) -> !s.testOnly && s.succeeds && s.language == codeLanguage
      )?.source

      try
        source = _.template(rawSource)(utils.i18n(plan, 'context'))
      catch e
        text = "Cannot auto fill solution: #{e.message}"
        console.error(text)
        noty({ type: 'error', text })

      unless _.isEmpty(source)
        commit('setLevelSolution', {
          autoFillCount: rootState.game.levelSolution.autoFillCount + 1,
          source
        })
      else
        noty({ text: "No solution available.", timeout: 3000 })
        console.error("Could not find solution for #{rootState.game.level.name}")
  }
  getters: {
    levelSolution: (state) -> state.levelSolution
  }
}

Backbone.Mediator.subscribe('level:set-playing', (e) ->
  playing = (e ? {}).playing ? true
  application.store.commit('game/setPlaying', playing)
)
