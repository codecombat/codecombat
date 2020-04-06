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
    tutorial: []
    tutorialActive: false
    codeBankOpen: false
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
    addTutorialStep: (state, step) ->
      if state.tutorial.find((s) ->
        return _.isEqual(step, s)
      )
        return

      if step.intro
        state.tutorial = [step, state.tutorial...]
      else
        state.tutorial.push(step)
    resetTutorial: (state) ->
      state.tutorial = []
    setTutorialActive: (state, tutorialActive) ->
      state.tutorialActive = tutorialActive
    setCodeBankOpen: (state, open) ->
      state.codeBankOpen = open
  }
  actions: {
    # Idempotent, will not add the same step twice
    addTutorialStep: ({ commit, rootState }, step) ->
      commit('addTutorialStep', step)
    setTutorialActive: ({ commit, rootState }, tutorialActive) ->
      commit('setTutorialActive', tutorialActive)
    restartTutorial: ({ commit, rootState }) ->
      commit('setTutorialActive', false)
      # Give it a moment to react first...
      setTimeout(() ->
        commit('setTutorialActive', true)
      , 500)
    resetTutorial: ({ commit }) ->
      commit('resetTutorial')
    # Idempotent, will not add the same step twice
    # Appends steps to the tutorial, extracting information from each say event in sayEvents
    addTutorialStepsFromSayEvents: ({ commit, rootState }, sayEvents) ->
      sayEvents.forEach((sayEvent) ->
        { say, tutorial } = sayEvent
        commit('addTutorialStep', {
          message: say.text
          # To stay backwards compatible with old Vega messages,
          # they are turned into stationary Vega messages with no other qualities:
          position: tutorial?.position or 'stationary'
          targetElement: tutorial?.targetElement
          animate: tutorial?.animate
          targetLine: tutorial?.targetLine
        })
      )
    toggleCodeBank: ({ commit, rootState }) ->
      commit('setCodeBankOpen', !rootState.game.codeBankOpen)
  }
  getters: {
    codeBankOpen: (state) -> state.codeBankOpen
    tutorialSteps: (state) -> state.tutorial
    tutorialActive: (state) -> state.tutorialActive
  }
}

Backbone.Mediator.subscribe('level:set-playing', (e) ->
  playing = (e ? {}).playing ? true
  application.store.commit('game/setPlaying', playing)
)
