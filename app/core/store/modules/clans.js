import { getPublicClans, getMyClans, getClan, getChildClanDetails, getTournamentsByClan } from '../../api/clans'
import { getTournamentsByMember } from '../../api/tournaments'
const _ = require('lodash')

export default {
  namespaced: true,
  state: {
    // key is clan id, with clan data stored as object literal.
    clans: {},
    // key is the clan id that initiated the request. Response array is memoized.
    childClanDetails: {},
    tournaments: {},
    loading: false,
    allTournamentsLoaded: false
  },

  getters: {
    isLoading (state) {
      return state.loading
    },

    myClans (state) {
      return (me.get('clans') || []).map(id => state.clans[id])
    },

    clanByIdOrSlug (state) {
      return idOrSlug => {
        return state.clans[idOrSlug] || Object.values(state.clans).find(({ slug }) => slug === idOrSlug)
      }
    },

    childClanDetails (state) {
      return id => {
        return state.childClanDetails[id] || []
      }
    },
    tournamentsByClan (state) {
      return clanId => {
        return state.tournaments[clanId]
      }
    },
    tournaments (state) {
      return state.tournaments
    },
    allTournamentsLoaded (state) {
      return state.allTournamentsLoaded
    }
  },

  mutations: {
    setClan (state, clan) {
      // We do not want to overwrite a clan with a version of the clan with less fields.
      // This can result in a clan losing a displayName and showing the slug as a result.
      if (state.clans[clan._id] && Object.keys(state.clans[clan._id]).length > Object.keys(clan).length) {
        return
      }

      Vue.set(state.clans, clan._id, clan)
    },

    setClanDetails (state, { clanId, childClans }) {
      Vue.set(state.childClanDetails, clanId, childClans)
    },

    setLoading (state, loading) {
      state.loading = loading
    },

    setTournaments (state, { clanId, tournaments }) {
      Vue.set(state.tournaments, clanId, tournaments)
    },

    loadAllTournaments (state) {
      state.allTournamentsLoaded = true
    }
  },

  actions: {
    async fetchRequiredInitialData ({ commit, dispatch }, { optionalIdOrSlug }) {
      commit('setLoading', true)
      try {
        const fetchPromises = [dispatch('fetchMyClans'), dispatch('fetchPublicClans')]
        if (optionalIdOrSlug) {
          fetchPromises.push(dispatch('fetchClan', { idOrSlug: optionalIdOrSlug }))
        }
        await Promise.all(fetchPromises)
      } catch (e) {
        console.error(e)
      }
      commit('setLoading', false)
    },

    async fetchMyClans ({ commit }) {
      const clans = await getMyClans()
      for (const clan of clans) {
        commit('setClan', clan)
      }
    },

    async fetchClan ({ commit }, { idOrSlug }) {
      const clan = await getClan(idOrSlug)
      if (clan) {
        commit('setClan', clan)
      }
    },

    async fetchPublicClans ({ commit }) {
      const clans = await getPublicClans()
      for (const clan of clans) {
        commit('setClan', clan)
      }
    },

    async fetchChildClanDetails ({ commit }, { id }) {
      const childClans = await getChildClanDetails(id)
      commit('setClanDetails', { clanId: id, childClans })
    },

    async fetchTournamentsForClan ({ commit }, { clanId }) {
      const tournaments = await getTournamentsByClan(clanId)
      if (tournaments) {
        commit('setTournaments', { clanId, tournaments: Object.values(tournaments)[0] })
      }
    },

    async fetchAllTournaments ({ commit }, { userId }) {
      const tournaments = await getTournamentsByMember(userId)
      if (tournaments) {
        const tournamentsByClan = _.groupBy(tournaments, 'clan')
        for (const key in tournamentsByClan) {
          commit('setTournaments', { clanId: key, tournaments: tournamentsByClan[key] })
        }
        commit('loadAllTournaments')
      }
    }
  }
}
