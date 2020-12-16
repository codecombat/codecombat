import { getLeaderboard, getMyRank } from '../../api/leaderboard'
import { fetchMySessions } from '../../api/level-sessions'

// Level called: Void-Rush
const currentSeasonalLevelOriginal = '5fad3d71bb7075d1dd20a1c0'

/**
 * We want to be able to fetch and store rankings for
 * various levels. I.e.
 * https://codecombat.com/db/level/5fad3d71bb7075d1dd20a1c0/rankings?order=-1&scoreOffset=1000000&limit=20&team=humans&_=1607469435140
 */
export default {
  namespaced: true,
  state: {
    loading: false,
    mySession: {},
    // level: {}, //Maybe level data is required?
    globalRankings: {
      globalTop: [],
      playersAbove: [],
      playersBelow: []
    },
    // key is clan id. Returns objects with same structure.
    rankingsForLeague: {}
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
    },

    setLeagueRanking (state, { leagueId, ranking }) {
      Vue.set(state.rankingsForLeague, leagueId, ranking)
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
    },

    clanRankings (state) {
      return (leagueId) => {
        if (!state.rankingsForLeague[leagueId]) {
          return []
        }
        const leagueRankings = state.rankingsForLeague[leagueId]
        if (state.mySession && state.mySession.rank > 20) {
          const splitRankings = []
          splitRankings.push(...state.leagueRankings.top.slice(0, 10))
          splitRankings.push({ type: 'BLANK_ROW' })
          splitRankings.push(...state.leagueRankings.playersAbove)
          splitRankings.push(state.mySession)
          splitRankings.push(...state.leagueRankings.playersBelow)
          return splitRankings
        }
        return leagueRankings.top
      }
    }
  },

  actions: {
    async loadGlobalRequiredData ({ commit, dispatch }) {
      commit('setLoading', true)
      const awaitPromises = [dispatch('fetchGlobalLeaderboard')]
      const sessionsData = await fetchMySessions(currentSeasonalLevelOriginal)

      if (Array.isArray(sessionsData) && sessionsData.length > 0) {
        const teamSession = sessionsData.find((session) => session.team === 'humans')
        if (!teamSession) {
          commit('setLoading', false)
          return
        }
        const score = teamSession.totalScore

        if (score !== undefined) {
          const [playersAbove, playersBelow, myRank] = await Promise.all([
            getLeaderboard(currentSeasonalLevelOriginal, { order: 1, scoreOffset: score, limit: 4 }),
            getLeaderboard(currentSeasonalLevelOriginal, { order: -1, scoreOffset: score, limit: 4 }),
            getMyRank(currentSeasonalLevelOriginal, teamSession._id, {
              scoreOffset: score,
              team: 'humans'
            })
          ])

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
      await Promise.all(awaitPromises)
      commit('setLoading', false)
    },

    async loadClanRequiredData ({ commit }, { leagueId }) {
      const leagueRankingInfo = {
        top: [],
        playersAbove: [],
        playersBelow: []
      }

      const topLeagueRankingPromise = getLeaderboard(currentSeasonalLevelOriginal, {
        order: -1,
        scoreOffset: 1000000,
        limit: 20,
        team: 'humans',
        'leagues.leagueID': leagueId
      }).then(ranking => {
        leagueRankingInfo.top = ranking
      })

      const sessionsData = await fetchMySessions(currentSeasonalLevelOriginal)

      if (Array.isArray(sessionsData) && sessionsData.length > 0) {
        const teamSession = sessionsData.find((session) => session.team === 'humans')
        if (!teamSession) {
          commit('setLoading', false)
          return
        }
        const score = (((teamSession.leagues || []).find(({ leagueID }) => leagueID === leagueId) || {}).stats || {}).totalScore

        if (score !== undefined) {
          const [ playersAbove, playersBelow, myRank ] = await Promise.all([
            getLeaderboard(currentSeasonalLevelOriginal, { order: 1, scoreOffset: score, limit: 4, 'leagues.leagueID': leagueId }),
            getLeaderboard(currentSeasonalLevelOriginal, { order: -1, scoreOffset: score, limit: 4, 'leagues.leagueID': leagueId }),
            getMyRank(currentSeasonalLevelOriginal, teamSession._id, {
              scoreOffset: score,
              team: 'humans',
              'leagues.leagueID': leagueId
            })
          ])

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
          leagueRankingInfo.playersAbove = playersAbove
          leagueRankingInfo.playersBelow = playersBelow

          commit('setMySession', teamSession)
        }
      }

      await topLeagueRankingPromise

      commit('setLeagueRanking', { leagueId: leagueId, ranking: leagueRankingInfo })
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
    }
  }
}
