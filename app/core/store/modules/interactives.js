import { getInteractive, getSession } from 'ozaria/site/api/interactive'

export default {
  namespaced: true,

  state: {
    loading: {
      interactive: false,
      session: false
    },

    interactive: undefined,
    interactiveSession: undefined
  },

  mutations: {
    toggleInteractiveLoading (state) {
      state.loading.interactive = !state.loading.interactive
    },

    toggleInteractiveSessionLoading (state) {
      state.loading.session = !state.loading.session
    },

    addInteractive (state, interactive) {
      state.interactive = interactive
    },

    addInteractiveSession (state, interactiveSession) {
      state.interactiveSession = interactiveSession
    }
  },

  getters: {
    currentInteractiveDataLoading (state) {
      return state.loading.interactive || state.loading.session
    },

    currentInteractive (state) {
      return state.interactive
    },

    currentInteractiveSession (state) {
      return state.interactiveSession
    },

    correctSubmissionFromSession (state, getters) {
      const currentInteractiveSession = getters.currentInteractiveSession
      if (!currentInteractiveSession) {
        return undefined
      }

      const submissions = currentInteractiveSession.submissions || []
      for (const submission of submissions) {
        if (submission.correct) {
          return submission
        }
      }

      return undefined
    }
  },

  actions: {
    async loadInteractive ({ commit }, interactiveIdOrSlug) {
      commit('toggleInteractiveLoading')

      try {
        const interactive = await getInteractive(interactiveIdOrSlug)
        if (!interactive) {
          throw new Error('Invalid interactive received')
        }

        commit('addInteractive', interactive)
      } catch (e) {
        // TODO handle_error_ozaria
        throw new Error('Failed to load interactive')
      } finally {
        commit('toggleInteractiveLoading')
      }
    },

    async loadInteractiveSession ({ commit }, { interactiveIdOrSlug, sessionOptions }) {
      commit('toggleInteractiveSessionLoading')

      try {
        const interactiveSession = await getSession(interactiveIdOrSlug, sessionOptions)
        if (!interactiveSession) {
          throw new Error('Invalid interactive session received')
        }

        commit('addInteractiveSession', interactiveSession)
      } catch (e) {
        // TODO handle_error_ozaria
        throw new Error('Failed to load interactive session')
      } finally {
        commit('toggleInteractiveSessionLoading')
      }
    }
  }
}
