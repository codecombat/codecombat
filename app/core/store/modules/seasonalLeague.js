import { getLeaderboard, getMyRank, getCodePointsLeaderboard, getCodePointsRankForUser } from '../../api/leaderboard'
import { fetchMySessions } from '../../api/level-sessions'

// Level called: Blazing Battle
const currentSeasonalLevelOriginal = '5fca06dc8b4da8002889dbf1'

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
    rankingsForLeague: {},
    codePointsRankingsForLeague: {}
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
    },

    setCodePointsRanking (state, { leagueId, ranking }) {
      Vue.set(state.codePointsRankingsForLeague, leagueId, ranking)
    },

    setMyCodePointsRank (state, myCodePointsRank) {
      state.myCodePointsRank = myCodePointsRank
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
          splitRankings.push(...leagueRankings.top.slice(0, 10))
          splitRankings.push({ type: 'BLANK_ROW' })
          splitRankings.push(...leagueRankings.playersAbove)
          splitRankings.push(state.mySession)
          splitRankings.push(...leagueRankings.playersBelow)
          return splitRankings
        }
        return leagueRankings.top
      }
    },

    codePointsRankings (state) {
      return (leagueId) => {
        if (!state.codePointsRankingsForLeague[leagueId]) {
          return []
        }
        const codePointsRankings = state.codePointsRankingsForLeague[leagueId]
        if (state.mySession && state.mySession.rank > 20) {
          const splitRankings = []
          splitRankings.push(...codePointsRankings.top.slice(0, 10))
          splitRankings.push({ type: 'BLANK_ROW' })
          splitRankings.push(...codePointsRankings.playersAbove)
          splitRankings.push(state.mySession)
          splitRankings.push(...codePointsRankings.playersBelow)
          return splitRankings
        }
        return codePointsRankings.top
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
        // Temporarily only choose unique sessions as duplicate AI sessions are returned.
        leagueRankingInfo.top = _.uniq(ranking, true, session => session._id)
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

    async loadCodePointsRequiredData ({ commit }, { leagueId }) {
      const codePointsRankingInfo = {
        top: [],
        playersAbove: [],
        playersBelow: []
      }

      const topCodePointsRankingPromise = getCodePointsLeaderboard(leagueId, {
        order: -1,
        scoreOffset: 1000000,
        limit: 20,
      }).then(ranking => {
        codePointsRankingInfo.top = ranking
      })

      if (me.get('stats') && me.get('stats').codePoints) {
        const [ playersAbove, playersBelow, myRank ] = await Promise.all([
          getCodePointsLeaderboard(leagueId, { order: 1, scoreOffset: me.get('stats').codePoints, limit: 4 }),
          getCodePointsLeaderboard(leagueId, { order: -1, scoreOffset: me.get('stats').codePoints, limit: 4 }),
          getCodePointsRankForUser(leagueId, me.id, { scoreOffset: me.get('stats').codePoints })
        ])

        let rank = parseInt(myRank, 10)
        for (const abovePlayer of playersAbove) {
          rank -= 1
          abovePlayer.rank = rank
        }
        playersAbove.reverse()
        rank = parseInt(myRank, 10)
        for (const belowPlayer of playersBelow) {
          rank += 1
          belowPlayer.rank = rank
        }

        const myPlayerRow = {creatorName: me.broadName(), rank: parseInt(myRank, 10)}
        codePointsRankingInfo.playersAbove = playersAbove
        codePointsRankingInfo.playersBelow = playersBelow

        commit('setMyCodePointsRank', myPlayerRow)
      }

      await topCodePointsRankingPromise

      commit('setCodePointsRanking', { leagueId: leagueId, ranking: codePointsRankingInfo })
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
