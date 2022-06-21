const fetchJson = require('../../api/fetch-json')
import { getNew, getList } from '../../api/announcements'

export default {
  namespaced: true,
  state: {
    announcementInterval: false,
    announcementModalOpen: false,
    announcements: [],
    unread: 0,
    display: {}
  },
  mutations: {
    setUnread (state, unread) {
      state.unread = unread
    },
    setAnnouncementInterval (state, interval) {
      state.announcementInterval = interval
    },
    setAnnouncementModalOpen (state, mode) {
      state.announcementModalOpen = mode
    },
    setAnnouncements (state, anns) {
      state.announcements = [...anns]
    },
    setDisplay (state, ann) {
      state.display = ann
    }
  },
  actions: {
    openAnnouncementModal ({ commit }, announcement) {
      commit('setDisplay', announcement)
      commit('setAnnouncementModalOpen', true)
    },
    closeAnnouncementModal ({commit}) {
      commit('setAnnouncementModalOpen', false)
    },
    startInterval ({commit, dispatch}) {
      let interval = setInterval(() => { dispatch('checkAnnouncements') }, 600000) // every 10 mins
      commit('setAnnouncementInterval', interval)
    },
    checkAnnouncements ({ commit }) {
      console.log('check announcements')
      if(me.isAnonymous()) {
        return
      }
      getNew().then((data) => {
        commit('setUnread', data.unread)
        if(data.sequence) {
          commit('setDisplay', data.sequence)
          commit('setAnnouncementModalOpen', true)
        }
      })
    },
    getAnnouncements ({ commit }) {
      getList().then((data) => {
        commit('setAnnouncements', data)
      })
    }
  },
  getters: {
    unread (state) {
      return state.unread
    },
    announcements (state) {
      return state.announcements
    },
    announcementInterval (state) {
      return state.announcementInterval
    },
    announcementModalOpen (state) {
      return state.announcementModalOpen
    },
    announcementDisplay (state) {
      return state.display
    }
  }
}