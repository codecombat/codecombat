import { getLeaderboard } from "../../api/leaderboard"

// Level called: Void-Rush
const currentSeasonalLevelOriginal = "5fad3d71bb7075d1dd20a1c0"

/**
 * We want to be able to fetch and store rankings for
 * various levels. I.e.
 * https://codecombat.com/db/level/5fad3d71bb7075d1dd20a1c0/rankings?order=-1&scoreOffset=1000000&limit=20&team=humans&_=1607469435140
 */
export default {
  namespaced: true,
  state: {
    loading: false,
    // level: {}, //Maybe level data is required?
    rankings: {
      global: []
    }
  },

  mutations: {
    setLoading (state, loading) {
      state.loading = loading
    },

    setGlobalRanking (state, rankingsList) {
      Vue.set(state.rankings, 'global', rankingsList)
    }
  },

  getters: {
    isLoading (state) {
      return state.loading
    },

    globalRankings (state) {
      return state.rankings.global
    }
  },

  actions: {
    async fetchGlobalLeaderboard ({ commit }) {
      commit('setLoading', true)
      const ranking = await getLeaderboard(currentSeasonalLevelOriginal, {
        order: -1,
        scoreOffset: 1000000,
        limit: 20,
        team: 'humans',
        '_': Math.floor(Math.random() * 100000000)
      })
      commit('setGlobalRanking', ranking)

      commit('setLoading', false)
    }
  }
}