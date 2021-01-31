import { getLeaderboard, getMyRank, getLeaderboardPlayerCount, getCodePointsLeaderboard, getCodePointsRankForUser } from '../../api/leaderboard'
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
      playersBelow: [],
      globalLeaderboardPlayerCount: 0
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

    setGlobalLeaderboardPlayerCount (state, count) {
      Vue.set(state.globalRankings, 'globalLeaderboardPlayerCount', count)
    },

    setMySession (state, mySession) {
      state.mySession = mySession
    },

    clearMySession (state) {
      state.mySession = {}
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

    globalLeaderboardPlayerCount (state) {
      return state.globalRankings.globalLeaderboardPlayerCount
    },

    globalRankings (state) {
      if (state.mySession && state.mySession.rank > 20) {
        const splitRankings = []
        splitRankings.push(...state.globalRankings.globalTop.slice(0, 10))
        splitRankings.push({ type: 'BLANK_ROW' })
        splitRankings.push(...state.globalRankings.playersAbove)
        // This hack is due to a race condition where the server returns the player
        // in the 4 above or 4 below. Thus we prevent player seeing duplicate of their result.
        if (![...state.globalRankings.playersAbove, ...state.globalRankings.playersBelow].some(ranking => ranking.creator === me.id)) {
          splitRankings.push(state.mySession)
        }
        splitRankings.push(...state.globalRankings.playersBelow)
        return splitRankings
      }
      return state.globalRankings.globalTop
    },

    clanLeaderboardPlayerCount (state) {
      return (leagueId) => {
        if (!state.rankingsForLeague[leagueId]) {
          return 0
        }
        const leagueRankings = state.rankingsForLeague[leagueId]
        return leagueRankings.leaderboardPlayerCount
      }
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
          // TODO: This uses `totalScore` which is possibly wrong if not global.
          splitRankings.push(state.mySession)
          splitRankings.push(...leagueRankings.playersBelow)
          return splitRankings
        }
        // TODO: This uses `totalScore` which is possibly wrong if not global.
        // As far as I can tell, if there are AI users they don't have the league Id.
        // The server may already be normalizing this from the returned rankings.
        return leagueRankings.top
      }
    },

    codePointsRankings (state) {
      return (leagueId) => {
        if (!state.codePointsRankingsForLeague[leagueId]) {
          return []
        }
        const codePointsRankings = state.codePointsRankingsForLeague[leagueId]
        try {
          if (state.myCodePointsRank && state.myCodePointsRank.rank > 20) {
            const splitRankings = []
            splitRankings.push(...codePointsRankings.top.slice(0, 10))
            splitRankings.push({ type: 'BLANK_ROW' })
            splitRankings.push(...codePointsRankings.playersAbove)
            splitRankings.push(state.myCodePointsRank)
            splitRankings.push(...codePointsRankings.playersBelow)
            return splitRankings
          }

          if (state.myCodePointsRank && typeof state.myCodePointsRank.rank === 'number' && state.myCodePointsRank.rank <= 20) {
            // This patches in the correct name and id if you are in the top 20.
            const rankIdx = state.myCodePointsRank.rank - 1
            const top = [...codePointsRankings.top]
            top[rankIdx] = {
              ...codePointsRankings.top[rankIdx],
              creator: me.id,
              creatorName: me.broadName()
            }
            return top
          }

          return codePointsRankings.top
        } catch (e) {
          // TODO - handle correctly. This is a hack to avoid strange situations as we are going fast.
          console.error(e)
        }
        return []
      }
    }
  },

  actions: {
    async loadGlobalRequiredData ({ commit, dispatch }) {
      commit('setLoading', true)
      commit('clearMySession')
      const awaitPromises = [
        dispatch('fetchGlobalLeaderboard'),
        dispatch('fetchGlobalLeaderboardPlayerCount')
      ]
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

          // TODO - Maybe server can fill these in, or we can query
          //        this more simply.
          teamSession.rank = parseInt(myRank, 10)
          teamSession.creatorName = me.broadName()

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
      commit('clearMySession')

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

      const leagueLeaderboardPlayerCountPromise = getLeaderboardPlayerCount(currentSeasonalLevelOriginal, {
        team: 'humans',
        'leagues.leagueID': leagueId
      }).then(playerCount => {
        leagueRankingInfo.leaderboardPlayerCount = parseInt(playerCount, 10)
      })

      const awaitPromises = [
        topLeagueRankingPromise,
        leagueLeaderboardPlayerCountPromise
      ]

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

      await Promise.all(awaitPromises)

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
        limit: 20
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

        // Required by the leaderboard to correctly show your user and highlight the row
        const myPlayerRow = {
          creatorName: me.broadName(),
          rank: parseInt(myRank, 10),
          totalScore: me.get('stats').codePoints,
          creator: me.id
        }

        codePointsRankingInfo.playersAbove = playersAbove
        codePointsRankingInfo.playersBelow = playersBelow

        // This edge case happens when we don't know the rank of the user.
        // In this case we want to wipe all rankings so we aren't guessing random ranks.
        if (myRank === 'unknown') {
          codePointsRankingInfo.playersAbove = playersAbove.map(session => { session.rank = ' '; return session })
          codePointsRankingInfo.playersBelow = playersBelow.map(session => { session.rank = ' '; return session })
          myPlayerRow.rank = ' '
        }

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
    },

    async fetchGlobalLeaderboardPlayerCount ({ commit }) {
      const playerCount = await getLeaderboardPlayerCount(currentSeasonalLevelOriginal, {})
      commit('setGlobalLeaderboardPlayerCount', parseInt(playerCount, 10))
    }
  }
}
