import fetchJson from 'app/core/api/fetch-json'

/**
 * Creates a new standards correlation in the database.
 * @async
 */
export const createNewStandards = ({ ...opts }, options = {}) =>
  fetchJson('/db/standards', _.assign({}, options, {
    method: 'POST',
    json: { ...opts }
  }))

export const getStandards = () => fetchJson('/db/standards')
