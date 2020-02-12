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

      state.tutorial.push(step)
    },
    setFirstStep: (state, step) => {
      state.tutorial = [
        step,
        ...state.tutorial
      ]
    },
    goToNextStep: (state) => state.currentTutorialIndex++
  },

  getters: {
    getCurrentStep: (state) => ({
      index: state.currentTutorialIndex,
      ...state.tutorial[state.currentTutorialIndex]
    }),
    getAllSteps: (state) => state.tutorial
  },

  actions: {
    addStep({ commit, rootState }, step) {
      commit('addStep', step)
    },

    goToNextStep({ commit }) {
      commit('goToNextStep')
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
