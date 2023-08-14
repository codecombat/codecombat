import fetchJson from 'app/core/api/fetch-json'

/**
 * Creates a new concept in the database.
 * @async
 */
export const createNewConcept = ({ ...opts }, options = {}) =>
  fetchJson('/db/concept', _.assign({}, options, {
    method: 'POST',
    json: { ...opts }
  }))

export const getConcepts = () => fetchJson('/db/concept')
