import utils from 'core/utils'

export default {
  namespaced: true,
  state: {
    tutorial: [],
    currentTutorialIndex: 0
  },

  mutations: {
    addStep: (state, step) => {
      if (state.tutorial.indexOf(step) > -1) {
        return
      }

      if (step.intro) {
        state.tutorial = [step, ...state.tutorial]
      } else {
        state.tutorial.push(step)
      }
    },
    goToNextStep: (state) => {
      if (state.currentTutorialIndex < state.tutorial.length - 1) {
        state.currentTutorialIndex++
      }
    },
    goToPreviousStep: (state) => {
      if (state.currentTutorialIndex > 0) {
        state.currentTutorialIndex--
      }
    }
  },

  getters: {
    currentStep: (state) => ({
      index: state.currentTutorialIndex,
      ...state.tutorial[state.currentTutorialIndex]
    }),
    isLastStep: (state) => state.currentTutorialIndex === state.tutorial.length - 1,
    isFirstStep: (state) => state.currentTutorialIndex === 0,
    allSteps: (state) => state.tutorial
  },

  actions: {
    addStep({ commit, rootState }, step) {
      commit('addStep', step)
    },

    goToNextStep({ commit }) {
      commit('goToNextStep')
    },

    goToPreviousStep({ commit }) {
      commit('goToPreviousStep')
    },

    buildTutorialFromSprites({ commit, rootState }, sprites) {
      sprites.filter(sprite => sprite.say).forEach(sprite => {
        commit('addStep', {
          message: utils.i18n(sprite.say, 'text'),
          elementTarget: sprite.tutorial ? sprite.tutorial.elementTarget : undefined,
          animate: sprite.tutorial ? sprite.tutorial.animate : undefined
        })
      })
    },
  }
}
