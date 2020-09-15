import fetchJson from 'app/core/api/fetch-json'

/**
 * Retrieves the stats for userId from user.stats collection
 * @param {string} userId - Id of the user.
 * @return {Promise<Object>} - User stats object
 */
export const getStatsForUser = userId => {
  if (!userId) {
    throw new Error(`No userId supplied`)
  }
  return fetchJson(`/db/user.stats/user/${userId}`)
}
