import { getAllEvents } from '../../api/events'

export default {
  namespaced: true,
  state: {
    events: {},
    loading: false
  },
  getters: {
    myEventInstances (state) {
      return Object.values(state.events).map(e => e.instances)
    }
  },
  mutations: {
    setEvent (state, event) {
      Vue.set(state.events, event._id, event)
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
