import fetchJson from 'app/core/api/fetch-json'

/**
 * Creates a new AI Junior Project in the database.
 * @async
 */
export const createNewAIJuniorProject = ({ ...opts }, options = {}) =>
  fetchJson('/db/ai_junior_project', _.assign({}, options, {
    method: 'POST',
    json: { ...opts }
  }))

export const getAIJuniorProjects = () => fetchJson('/db/ai_junior_project')
