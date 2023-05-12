import fetchJson from 'app/core/api/fetch-json'

/**
 * Creates a new AI Document in the database.
 * @async
 */
export const createNewAIDocument = ({ ...opts }, options = {}) =>
  fetchJson('/db/ai_document', _.assign({}, options, {
    method: 'POST',
    json: { ...opts }
  }))

export const getAIDocuments = () => fetchJson('/db/ai_document')
