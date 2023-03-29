import {
  getAllEvents, getEvent, getEventsByUser,
  postEvent, updateEvent,
  postEventMember, putEventMember, deleteEventMember,
  getInstances,
  putInstance
} from '../../api/events'

import { getFullNames } from '../../api/users'

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
    },

    memberNames: {}
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
    },

    allMemberIds (state) {
      const members = Object.values(state.events).map(event => [...(event.members || []), ...(event.removedMembers || [])]).flat()
      return Array.from(new Set(members.map(m => m.userId)))
    },
    memberNames (state) {
      return state.memberNames
    }
  },
  mutations: {
    setEvent (state, event) {
      Vue.set(state.events, event._id, event)
    },
    selectEvent (state, { eventId = undefined, event = undefined, instance = undefined } = {}) {
      if (eventId) {
        event = state.events[eventId]
      }
      if (instance) {
        event = instance.extendedProps
        delete instance.extendedProps
        const ins = event.instances.find(ins => ins._id === instance.id)
        Vue.set(state.eventPanel, 'editableInstance', ins)
      }
      Vue.set(state.eventPanel, 'editableEvent', event)
    },
    openPanel (state, type = 'info') {
      Vue.set(state.eventPanel, 'type', type)
      Vue.set(state.eventPanel, 'visible', true)
    },
    changeEventPanelTab (state, type = 'edit') {
      Vue.set(state.eventPanel, 'type', type)
    },
    closeEventPanel (state) {
      Vue.set(state.eventPanel, 'visible', false)
    },
    setMemberNames (state, names) {
      Vue.set(state, 'memberNames', names)
    }
  },
  actions: {
    openEventPanel ({ commit }, { type = 'info', eventId = undefined, event = undefined, instance = undefined } = {}) {
      commit('selectEvent', { event, instance })
      commit('openPanel', type)
    },
    async fetchAllEvents ({ commit }) {
      const events = await getAllEvents()
      for (const event of events) {
        event.instances = await getInstances(event._id)
      }
      for (const event of events) {
        commit('setEvent', event)
      }
    },
    async fetchUserEvents ({ commit }, uId) {
      const events = await getEventsByUser(uId)
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
    },
    async fetchMemberNames ({ getters, commit }) {
      const names = await getFullNames({ ids: getters.allMemberIds, from: 'online-classes' })
      commit('setMemberNames', names)
      return names
    }
  }
}
