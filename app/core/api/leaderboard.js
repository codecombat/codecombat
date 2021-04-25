import fetchJson from './fetch-json'

/**
 * Creates a get request to fetch ladder rankings for a ladder.
 * Will construct a string that looks similar to:
 * `https://codecombat.com/db/level/5fad3d71bb7075d1dd20a1c0/rankings?order=-1&scoreOffset=1000000&limit=20&team=humans&_=1607469435140`
 * @param {string} levelOriginal level to fetch ranking from. Must have level type `ladder`.
 * @param {Object} options Coverted into query params.
 */
export const getLeaderboard = (levelOriginal, options) => {
  return fetchJson(`/db/level/${levelOriginal}/rankings?${$.param(options)}`)
}

export const getMyRank = (levelOriginal, sessionId, options) => {
  return fetchJson(`/db/level/${levelOriginal}/rankings/${sessionId}?${$.param(options)}`)
}

export const getLeaderboardPlayerCount = (levelOriginal, options) => {
  return fetchJson(`/db/level/${levelOriginal}/rankings-count?${$.param(options)}`)
}

export const getCodePointsLeaderboard = (clanId, options) => {
  return fetchJson(`/db/clan/${clanId || '-'}/code-points?${$.param(options)}`)
}

export const getCodePointsRankForUser = (clanId, userId, options) => {
  return fetchJson(`/db/clan/${clanId || '-'}/code-points/user/${userId || me.id}?${$.param(options)}`)
}

export const getCodePointsPlayerCount = (clanId, options) => {
  return fetchJson(`/db/clan/${clanId || '-'}/code-points-member-count?${$.param(options)}`);
};
