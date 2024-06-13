import fetchJson from 'app/core/api/fetch-json'

export const createAIJuniorScenario = ({ ...opts }, options = {}) =>
  fetchJson('/db/ai_junior_scenario', _.assign({}, options, {
    method: 'POST',
    json: { ...opts }
  }))

export const getAIJuniorScenarios = (options = {}) => fetchJson('/db/ai_junior_scenario', options)

export const getAIJuniorScenario = ({ scenarioHandle }, options = {}) => fetchJson(`/db/ai_junior_scenario/${scenarioHandle}`, options)
