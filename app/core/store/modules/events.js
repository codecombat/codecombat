import { getAllEvents, postEvent, updateEvent, putEventMember, deleteEventMember } from '../../api/events'

export default {
  namespaced: true,
  state: {
    events: {},
    loading: false,

    eventPanel: {
      visible: false,
      type: 'info',
      editableEvent: undefined
    }
  },
  getters: {
    events(state) {
      return state.events
    },
    eventPanelVisible (state) {
      return state.eventPanel.visible
    },
    eventPanelType (state) {
      return state.eventPanel.type
    },
    eventPanelEvent (state) {
      return state.eventPanel.editableEvent
    }
  },
  mutations: {
    setEvent (state, event) {
      Vue.set(state.events, event._id, event)
    },
    openEventPanel (state, { type = 'info', event = undefined } = {}) {
      Vue.set(state.eventPanel, 'visible', true)
      Vue.set(state.eventPanel, 'type', type)
      Vue.set(state.eventPanel, 'editableEvent', event)
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
    },
    async saveEvent ({ commit }, event) {
      await postEvent(event)
    },
    async editEvent ({ commit }, event) {
      await updateEvent(event._id, event)
    },
    async addEventMember ({ commit }, event, member) {
      await putEventMember(event._id, member)
    },
    async delEventMember ({ commit }, event, member) {
      await deleteEventMember(event._id, member)
    }
  }
}
