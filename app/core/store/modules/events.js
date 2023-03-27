import {
  getAllEvents, getEvent,
  postEvent, updateEvent,
  postEventMember, putEventMember, deleteEventMember,
  getInstances,
  putInstance
} from '../../api/events'

export default {
  namespaced: true,
  state: {
    events: {},
    loading: false,

    eventPanel: {
      visible: false,
      type: 'info',
      editableEvent: undefined,
      editableInstance: undefined
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
    },
    eventPanelInstance (state) {
      return state.eventPanel.editableInstance
    }
  },
  mutations: {
    setEvent (state, event) {
      Vue.set(state.events, event._id, event)
    },
    openEventPanel (state, { type = 'info', eventId = undefined, event = undefined, instance = undefined } = {}) {
      Vue.set(state.eventPanel, 'visible', true)
      Vue.set(state.eventPanel, 'type', type)
      if (eventId) {
        event = state.events[eventId]
      }
      if (instance) {
        event = instance.extendedProps
        delete instance.extendedProps
        const ins = event.instances.find(ins => ins._id === instance.id)
        ins.ownerName = event.ownerName
        Vue.set(state.eventPanel, 'editableInstance', ins)
      }
      Vue.set(state.eventPanel, 'editableEvent', event)
    },
    changeEventPanelTab (state, type = 'edit') {
      Vue.set(state.eventPanel, 'type', type)
    },
    closeEventPanel (state) {
      Vue.set(state.eventPanel, 'visible', false)
    }
  },
  actions: {
    async fetchAllEvents ({ commit }) {
      const events = await getAllEvents()
      for (const event of events) {
        event.instances = await getInstances(event._id)
      }
      for (const event of events) {
        commit('setEvent', event)
      }
    },
    async fetchEvent ({ commit }, eventId) {
      const event = await getEvent(eventId)
      event.instances = await getInstances(eventId)
      commit('setEvent', event)
    },
    async saveEvent ({ commit }, event) {
      await postEvent(event)
    },
    async editEvent ({ commit }, event) {
      await updateEvent(event._id, event)
    },
    async addEventMember ({ commit }, { eventId, member } = {}) {
      await postEventMember(eventId, member)
    },
    async editEventMember ({ commit }, { eventId, member } = {}) {
      await putEventMember(eventId, member)
    },
    async delEventMember ({ commit }, {eventId, member} = {}) {
      await deleteEventMember(eventId, member)
    },
    async saveInstance ({ commit }, instance) {
      await putInstance(instance._id, instance)
    }
  }
}
