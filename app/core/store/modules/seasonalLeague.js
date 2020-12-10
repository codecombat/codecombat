import { getLeaderboard, getMyRank } from '../../api/leaderboard'
import { fetchMySessions } from '../../api/level-sessions'

// Level called: Void-Rush
// const currentSeasonalLevelOriginal = '5fad3d71bb7075d1dd20a1c0'

// Zero-sum for testing
const currentSeasonalLevelOriginal = '550363b4ec31df9c691ab629'

/**
 * We want to be able to fetch and store rankings for
 * various levels. I.e.
 * https://codecombat.com/db/level/5fad3d71bb7075d1dd20a1c0/rankings?order=-1&scoreOffset=1000000&limit=20&team=humans&_=1607469435140
 */
export default {
  namespaced: true,
  state: {
    loading: false,
    mySession: [],
    // level: {}, //Maybe level data is required?
    globalRankings: {
      globalTop: [],
      playersAbove: [],
      playersBelow: []
    },
    // key is clan id. Returns objects with same structure.
    rankingsForClan: {}
  },

  mutations: {
    setLoading (state, loading) {
      state.loading = loading
    },

    setGlobalRanking (state, rankingsList) {
      Vue.set(state.globalRankings, 'globalTop', rankingsList)
    },

    setGlobalAbove (state, above) {
      Vue.set(state.globalRankings, 'playersAbove', above)
    },

    setGlobalBelow (state, below) {
      Vue.set(state.globalRankings, 'playersBelow', below)
    },

    setMySession (state, mySession) {
      state.mySession = mySession
    }
  },

  getters: {
    isLoading (state) {
      return state.loading
    },

    globalRankings (state) {
      if (state.mySession && state.mySession.rank > 20) {
        const splitRankings = []
        splitRankings.push(...state.globalRankings.globalTop.slice(0, 10))
        splitRankings.push({ type: 'BLANK_ROW' })
        splitRankings.push(...state.globalRankings.playersAbove)
        splitRankings.push(state.mySession)
        splitRankings.push(...state.globalRankings.playersBelow)
        return splitRankings
      }
      return state.globalRankings.globalTop
    }
  },

  actions: {
    async loadGlobalRequiredData ({ commit, dispatch }) {
      commit('setLoading', true)
      const sessionsData = await fetchMySessions(currentSeasonalLevelOriginal)
      console.log({ sessionsData })
      await dispatch('fetchGlobalLeaderboard')

      if (Array.isArray(sessionsData) && sessionsData.length > 0) {
        const teamSession = sessionsData.find((session) => session.team === 'humans')
        const score = teamSession.totalScore

        if (score !== undefined) {
          const playersAbove = await getLeaderboard(currentSeasonalLevelOriginal, { order: 1, scoreOffset: score, limit: 4 })
          const playersBelow = await getLeaderboard(currentSeasonalLevelOriginal, { order: -1, scoreOffset: score, limit: 4 })

          const myRank = await getMyRank(currentSeasonalLevelOriginal, teamSession._id, {
            scoreOffset: score,
            team: 'humans'
          })

          let rank = parseInt(myRank, 10)
          for (const aboveSession of playersAbove) {
            rank -= 1
            aboveSession.rank = rank
          }
          playersAbove.reverse()
          rank = parseInt(myRank, 10)
          for (const belowSession of playersBelow) {
            rank += 1
            belowSession.rank = rank
          }

          teamSession.rank = parseInt(myRank, 10)
          commit('setMySession', teamSession)
          commit('setGlobalAbove', playersAbove)
          commit('setGlobalBelow', playersBelow)
        }
      }

      commit('setLoading', false)
    },

    async loadLeagueRequiredData ({ commit, dispatch }) {
      // TODO - Same as global path but with league specific...
    },

    async fetchGlobalLeaderboard ({ commit }) {
      const ranking = await getLeaderboard(currentSeasonalLevelOriginal, {
        order: -1,
        scoreOffset: 1000000,
        limit: 20,
        team: 'humans',
        '_': Math.floor(Math.random() * 100000000)
      })
      commit('setGlobalRanking', ranking)
    },

    async fetchClanLeaderboard ({ commit }) {
      // TODO: Load a leaderboard for the clan specifically.
      //       By default show top 20.
      //       If the user is in the rankings then show 10, and then ... row.
    }
  }
}
