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
    hasPlayedGame: false
    # Source for solving the level, and number of times it has been used:
    levelSolution: {
      autoFillCount: 0,
      source: ''
    }
  }
  mutations: {
    setPlaying: (state, playing) ->
      state.playing = playing
    setLevel: (state, updates) ->
      state.level = $.extend(true, {}, updates)
    setLevelSolution: (state, solution) ->
      state.levelSolution = solution
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
        # There is a function property that needs to be omitted because they don't compare
        return _.isEqual(_.omit(step, _.functions(step)), _.omit(s, _.functions(s)))
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
    setHasPlayedGame: (state, hasPlayed) ->
      state.hasPlayedGame = hasPlayed
  }
  actions: {
    # Idempotent, will not add the same step twice
    addTutorialStep: ({ commit, rootState, dispatch }, step) ->
      # Turns voiceOver property into a function to play voice over if possible.

      if step.voiceOver
        soundIdPromise = dispatch('voiceOver/preload', step.voiceOver, { root: true })
        # Lazy function we can call to play the voice over.
        # TODO: Localize by passing in different file path based on i18n.
        step.playVoiceOver = () => dispatch('voiceOver/playVoiceOver', soundIdPromise, { root: true })


      commit('addTutorialStep', step)
    setTutorialActive: ({ commit, rootState }, tutorialActive) ->
      commit('setTutorialActive', tutorialActive)
    restartTutorial: ({ commit }) ->
      commit('setTutorialActive', false)
      # Give it a moment to react first...
      setTimeout(() ->
        commit('setTutorialActive', true)
      , 500)
    resetTutorial: ({ commit }, options) ->
      commit('resetTutorial', options)
    # Idempotent, will not add the same step twice
    # Appends steps to the tutorial, extracting information from each say event in sayEvents
    addTutorialStepsFromSayEvents: ({ commit, rootState, dispatch }, sayEvents) ->
      sayEvents.forEach((sayEvent) ->
        { say, tutorial } = sayEvent

        dispatch('addTutorialStep', {
          message: utils.i18n(say, 'text')
          # To stay backwards compatible with old Vega messages,
          # they are turned into stationary Vega messages with no other qualities:
          position: tutorial?.position or 'stationary'
          targetElement: tutorial?.targetElement
          animation: tutorial?.animation
          targetLine: tutorial?.targetLine
          targetThangs: tutorial?.targetThangs
          grayOverlay: tutorial?.grayOverlay
          advanceOnTarget: tutorial?.advanceOnTarget
          internalRelease: tutorial?.internalRelease
          voiceOver: say.voiceOver
        })
      )
    toggleCodeBank: ({ commit, rootState }) ->
      commit('setCodeBankOpen', !rootState.game.codeBankOpen)
    setClickedUpdateCapstoneCode: ({ commit }, clicked) ->
      commit('setClickedUpdateCapstoneCode', clicked)
    setHasPlayedGame: ({ commit }, hasPlayed) ->
      commit('setHasPlayedGame', hasPlayed)
    autoFillSolution: ({ commit, rootState }) ->
      try
        hero = _.find (rootState.game.level?.thangs ? []), id: 'Hero Placeholder'
        component = _.find(hero.components ? [], (x) -> x?.config?.programmableMethods?.plan)
        plan = component.config?.programmableMethods?.plan
        # This can live in Vuex at some point
        codeLanguage = utils.getQueryVariable('codeLanguage') ? 'python'
        rawSource = plan.solutions?.find((s) -> !s.testOnly && s.succeeds && s.language == codeLanguage)?.source
        external_ch1_avatar = rootState.me.ozariaUserOptions?.avatar?.avatarCodeString ? 'crown'
        context = _.merge({ external_ch1_avatar }, utils.i18n(plan, 'context'))
        source = _.template(rawSource)(context)

        unless _.isEmpty(source)
          commit('setLevelSolution', {
            autoFillCount: rootState.game.levelSolution.autoFillCount + 1,
            source
          })
        else
          noty({ text: "No solution available.", timeout: 3000 })
          console.error("Could not find solution for #{rootState.game.level.name}")
      catch e
        text = "Cannot auto fill solution: #{e.message}"
        console.error(text)
        noty({ type: 'error', text })
  }
  getters: {
    codeBankOpen: (state) -> state.codeBankOpen
    tutorialSteps: (state) -> state.tutorial
    tutorialActive: (state) -> state.tutorialActive
    clickedUpdateCapstoneCode: (state) -> state.clickedUpdateCapstoneCode
    hasPlayedGame: (state) -> state.hasPlayedGame
    levelSolution: (state) -> state.levelSolution
  }
}

Backbone.Mediator.subscribe('level:set-playing', (e) ->
  playing = (e ? {}).playing ? true
  application.store.commit('game/setPlaying', playing)
)
