// Fixed value. Can be set dynamically by content in the future if required.
const X_OFFSET_HIDDEN = 200

export default {
  namespaced: true,

  state: {
    chalkboardMarkdown: 'Temporary Text',
    // Starting defaults chosen by content team.
    width: 45,
    height: 75,
    xOffset: 46,
    yOffset: 26,
    xOffsetHiddenOverride: X_OFFSET_HIDDEN, // Used to animate chalkboard on and off the screen
    transitionTime: 1
  },

  mutations: {
    setChalkboardContents (state, markdown) {
      state.chalkboardMarkdown = markdown
    },

    setChalkboardDimensions (state, { width, height }) {
      if (width) {
        state.width = width
      }
      if (height) {
        state.height = height
      }
    },

    setChalkboardOffset (state, { xOffset, yOffset }) {
      if (xOffset) {
        state.xOffset = xOffset
      }
      if (yOffset) {
        state.yOffset = yOffset
      }
    },

    setOffsetForHiding (state, { xOffset }) {
      state.xOffsetHiddenOverride = xOffset
    },

    setTransitionTime (state, time) {
      state.transitionTime = time
    }
  },

  actions: {
    changeChalkboardContents ({ commit }, { markdown, width, height, xOffset, yOffset }) {
      if (markdown) {
        commit('setChalkboardContents', markdown)
      }
      commit('setChalkboardDimensions', { width, height })
      commit('setChalkboardOffset', { xOffset, yOffset })
    },

    showVisualChalkboard ({ commit }, isShown) {
      if (isShown) {
        commit('setOffsetForHiding', { xOffset: 0 })
      } else {
        commit('setOffsetForHiding', { xOffset: X_OFFSET_HIDDEN })
      }
    },

    instantVisualChalkboardMove ({ commit }, { xOffset, yOffset }) {
      commit('setTransitionTime', 0)
      commit('setChalkboardOffset', { xOffset, yOffset })
      window.requestAnimationFrame(() => commit('setTransitionTime', 1))
    },

    instantShowVisualChalkboard ({ commit }, isShown) {
      commit('setTransitionTime', 0)
      if (isShown) {
        commit('setOffsetForHiding', { xOffset: 0 })
      } else {
        commit('setOffsetForHiding', { xOffset: X_OFFSET_HIDDEN })
      }
      window.requestAnimationFrame(() => commit('setTransitionTime', 1))
    }
  }
}
