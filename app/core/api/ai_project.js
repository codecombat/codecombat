import fetchJson from 'app/core/api/fetch-json'

/**
 * Creates a new AI Project in the database.
 * @async
 */
export const createNewAIProject = ({ ...opts }, options = {}) =>
  fetchJson('/db/ai_project', _.assign({}, options, {
    method: 'POST',
    json: { ...opts }
  }))

export const getAIProjects = () => fetchJson('/db/ai_project')

