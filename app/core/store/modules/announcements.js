const fetchJson = require('../../api/fetch-json')
import { getNew, getList, read } from '../../api/announcements'

export default {
  namespaced: true,
  state: {
    announcementInterval: false,
    announcementModalOpen: false,
    announcements: [],
    unread: 0,
    display: {},
    moreAnnouncements: true
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
    setAnnouncements (state, {anns, append}) {
      if(append) {
        state.announcements = [...state.announcements, ...anns]
      }
      else
        state.announcements = [...anns]
    },
    setDisplay (state, ann) {
      state.display = ann
    },
    readAnnouncement (state, id) {
      state.announcements = state.announcements.map(ann => {
        if(ann._id == id) {
          ann.read = true
        }
        ann
      })
    },
    setMoreAnnouncement (state, more) {
      state.moreAnnouncements = more
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
    getAnnouncements ({ commit }, options) {
      let append = false
      if(options)
        append = options.append
      getList(options).then((data) => {
        commit('setAnnouncements', {anns: data, append})
        if(!data.length) {
          commit('setMoreAnnouncement', false)
        }
      })
    },
    readAnnouncement ({commit}, id) {
      read({announcement: id}).then((data) => {
        commit('readAnnouncement', id)
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
    },
    moreAnnouncements (state) {
      return state.moreAnnouncements
    }
  }
}