import fetchJson from 'app/core/api/fetch-json'

/**
 * Creates a new AI Interaction in the database.
 * @async
 */
export const createNewAIInteraction = ({ ...opts }, options = {}) =>
  fetchJson('/db/ai_interaction', _.assign({}, options, {
    method: 'POST',
    json: { ...opts }
  }))

export const getAIInteractions = () => fetchJson('/db/ai_interaction')
