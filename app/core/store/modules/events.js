import { getAllEvents } from '../../api/events'

export default {
  namespaced: true,
  state: {
    events: {},
    loading: false,

    eventPanel: {
      visible: false
    }
  },
  getters: {
    myEventInstances (state) {
      return Object.values(state.events).map(e => e.instances)
    },
    eventPanelVisible (state) {
      return state.eventPanel.visible
    }
  },
  mutations: {
    setEvent (state, event) {
      Vue.set(state.events, event._id, event)
    },
    openEventPanel (state) {
      Vue.set(state.eventPanel, 'visible', true)
    },
    closeEventPanel (state) {
      Vue.set(state.eventPanel, 'visible', false)
    }
  },
  actions: {
    async fetchAllEvents ({ commit }) {
      const events = await getAllEvents()
      for (const event of events) {
        commit('setEvent', event)
      }
    }
  }
}
