import fetchJson from 'app/core/api/fetch-json'

/**
 * Creates a new AI Junior Scenario in the database.
 * @async
 */
export const createNewAIJuniorScenario = ({ ...opts }, options = {}) =>
  fetchJson('/db/ai_junior_scenario', _.assign({}, options, {
    method: 'POST',
    json: { ...opts }
  }))

export const getAIJuniorScenarios = () => fetchJson('/db/ai_junior_scenario')
