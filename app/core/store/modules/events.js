import {
  getAllEvents, getEvent, getEventsByUser,
  postEvent, updateEvent,
  postEventMember, putEventMember, deleteEventMember,
  syncToGoogleFailed,
  getInstances,
  putInstance
} from '../../api/events'

import { getFullNames } from '../../api/users'
import { getMembersByClassCode } from '../../api/classrooms'

export default {
  namespaced: true,
  state: {
    events: {}, // be an object to avoid same event entries
    loading: false,

    eventPanel: {
      visible: false,
      type: 'info',
      clickedDate: undefined,
      editableEvent: undefined,
      editableInstance: undefined
    },

    teacherNames: {},
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
    eventPanelDate (state) {
      return state.eventPanel.clickedDate
    },
    eventPanelEvent (state) {
      return state.eventPanel.editableEvent
    },
    eventPanelInstance (state) {
      return state.eventPanel.editableInstance
    },

    // TODO: fetch all online-teachers here
    allTeacherIds (state) {
      const teachers = Object.values(state.events).map(event => event.owner)
      return Array.from(new Set(teachers))
    },
    teacherNames (state) {
      const teachers = {}
      Object.values(state.events).map(event => (teachers[event.owner] = event.ownerName))
      return teachers
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
    cancelPreviewEvent (state, id = 'temp-event') {
      Vue.delete(state.events, id)
    },
    selectEvent (state, { eventId, event, instance } = {}) {
      if (eventId) {
        event = state.events[eventId]
      }
      if (instance) {
        event = instance.extendedProps
        delete instance.extendedProps
        const ins = event.instances.find(ins => ins._id === instance.id)
        ins.meetingLink = event.meetingLink
        Vue.set(state.eventPanel, 'editableInstance', ins)
      }
      Vue.set(state.eventPanel, 'editableEvent', event)
    },
    openPanel (state, { type = 'info', date = undefined }) {
      Vue.set(state.eventPanel, 'type', type)
      Vue.set(state.eventPanel, 'clickedDate', date)
      Vue.set(state.eventPanel, 'visible', true)
    },
    changeEventPanelTab (state, type = 'edit') {
      Vue.set(state.eventPanel, 'type', type)
    },
    closeEventPanel (state) {
      Vue.set(state.eventPanel, 'visible', false)
      Vue.delete(state.events, 'temp-event') // always remove preview
    },
    setMemberNames (state, names) {
      Vue.set(state, 'memberNames', names)
    }
  },
  actions: {
    openEventPanel ({ commit }, { type = 'info', date, eventId, event, instance } = {}) {
      commit('selectEvent', { event, instance })
      commit('openPanel', { type, date })
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
      return await postEvent(event)
    },
    async editEvent ({ commit }, event) {
      return await updateEvent(event._id, event)
    },
    async addEventMember ({ commit }, { eventId, member } = {}) {
      return await postEventMember(eventId, member)
    },
    async editEventMember ({ commit }, { eventId, member } = {}) {
      return await putEventMember(eventId, member)
    },
    async delEventMember ({ commit }, {eventId, member} = {}) {
      return await deleteEventMember(eventId, member)
    },
    async syncToGoogleFailed ({ commit }, eventId) {
      return await syncToGoogleFailed(eventId)
    },
    async saveInstance ({ commit }, instance) {
      return await putInstance(instance._id, instance)
    },
    async fetchMemberNames ({ getters, commit }) {
      const names = await getFullNames({ ids: getters.allMemberIds, from: 'online-classes' })
      commit('setMemberNames', names)
      return names
    },

    async importMembersFromClass ({ commit }, { classCode }) {
      const members = await getMembersByClassCode(classCode)
      return members
    },
  }
}
