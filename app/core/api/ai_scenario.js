import fetchJson from 'app/core/api/fetch-json'

/**
 * Creates a new AI Scenario in the database.
 * @async
 */
export const createNewAIScenario = ({ ...opts }, options = {}) =>
  fetchJson('/db/ai_scenario', _.assign({}, options, {
    method: 'POST',
    json: { ...opts }
  }))

export const getAIScenarios = () => fetchJson('/db/ai_scenario')

