levelSchema = require('schemas/models/level')
api = require('core/api')
utils = require('core/utils')

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
    clickedUpdateCapstoneCode: false
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
    resetTutorial: (state, options = {}) ->
      state.tutorialActive = false
      if options.keepIntro && state.tutorial[0]?.intro
        state.tutorial = [state.tutorial[0]]
      else
        state.tutorial = []
    setTutorialActive: (state, tutorialActive) ->
      state.tutorialActive = tutorialActive
    setCodeBankOpen: (state, open) ->
      state.codeBankOpen = open
    setClickedUpdateCapstoneCode: (state, clicked) ->
      state.clickedUpdateCapstoneCode = clicked
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
    resetTutorial: ({ commit }, options) ->
      commit('resetTutorial', options)
    # Idempotent, will not add the same step twice
    # Appends steps to the tutorial, extracting information from each say event in sayEvents
    addTutorialStepsFromSayEvents: ({ commit, rootState }, sayEvents) ->
      sayEvents.forEach((sayEvent) ->
        { say, tutorial } = sayEvent
        commit('addTutorialStep', {
          message: utils.i18n(say, 'text')
          # To stay backwards compatible with old Vega messages,
          # they are turned into stationary Vega messages with no other qualities:
          position: tutorial?.position or 'stationary'
          targetElement: tutorial?.targetElement
          animation: tutorial?.animation
          targetLine: tutorial?.targetLine
          grayOverlay: tutorial?.grayOverlay
          advanceOnTarget: tutorial?.advanceOnTarget
          internalRelease: tutorial?.internalRelease
        })
      )
    toggleCodeBank: ({ commit, rootState }) ->
      commit('setCodeBankOpen', !rootState.game.codeBankOpen)
    setClickedUpdateCapstoneCode: ({ commit }, clicked) ->
      commit('setClickedUpdateCapstoneCode', clicked)
  }
  getters: {
    codeBankOpen: (state) -> state.codeBankOpen
    tutorialSteps: (state) -> state.tutorial
    tutorialActive: (state) -> state.tutorialActive
    clickedUpdateCapstoneCode: (state) -> state.clickedUpdateCapstoneCode
  }
}

Backbone.Mediator.subscribe('level:set-playing', (e) ->
  playing = (e ? {}).playing ? true
  application.store.commit('game/setPlaying', playing)
)
