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
    moreAnnouncements: true,
    showMoreAnnouncementButton: false
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
        anns.forEach((ann) => {
          if(!_.find(state.announcements, {_id: ann._id})) {
            state.announcements.push(ann)
          }
        })
      }
      else
        state.announcements = [...anns]
    },
    setDisplay (state, ann) {
      state.display = ann
    },
    readAnnouncement (state, id) {
      state.announcements = state.announcements.map((ann) => {
        if(ann._id == id) {
          if(!ann.read) {
            state.unread -= 1;
          }
          ann.read = true
        }
        return ann
      })
    },
    setMoreAnnouncement (state, more) {
      state.moreAnnouncements = more
    },
    setShowMoreButton (state, more) {
      state.showMoreAnnouncementButton = more
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
    startInterval ({commit, dispatch}, fromNav) {
      let interval = setInterval(() => { dispatch('checkAnnouncements', fromNav) }, 600000) // every 10 mins
      commit('setAnnouncementInterval', interval)
    },
    checkAnnouncements ({ commit }, fromNav) {
      if(me.isAnonymous()) {
        return
      }
      getNew().then((data) => {
        commit('setUnread', data.unread)
        if(data.sequence) {
          commit('setDisplay', data.sequence)
          commit('setAnnouncementModalOpen', true)
          commit('setShowMoreButton', fromNav)
        }
      })
    },
    getAnnouncements ({ commit }, options) {
      let append = false
      commit('setShowMoreButton', false)
      if(options)
        append = options.append
      getList(options).then((data) => {
        commit('setAnnouncements', {anns: data, append})
        if(append && !data.length) {
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
    },
    showMoreAnnouncementButton (state) {
      return state.showMoreAnnouncementButton
    }
  }
}