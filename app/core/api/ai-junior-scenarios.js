import fetchJson from 'app/core/api/fetch-json'

export const createAIJuniorScenario = ({ ...opts }, options = {}) =>
  fetchJson('/db/ai_junior_scenario', _.assign({}, options, {
    method: 'POST',
    json: { ...opts },
  }))

export const getAIJuniorScenarios = (options = {}) => fetchJson('/db/ai_junior_scenario', options)

export const getAIJuniorScenario = ({ scenarioHandle }, options = {}) => fetchJson(`/db/ai_junior_scenario/${encodeURIComponent(scenarioHandle)}`, options)

// Coalesce a class's simultaneous requests for the same scenario. Do not keep
// resolved codes cached: each print checks for new collisions and versions.
const pendingWorksheetCodes = new Map()
export const resolveAIJuniorWorksheetCode = (code) => {
  if (pendingWorksheetCodes.has(code)) return pendingWorksheetCodes.get(code)
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), 5000)
  const pending = fetchJson(`/s/${encodeURIComponent(code)}?format=json`, { signal: controller.signal }).finally(() => {
    clearTimeout(timeout)
    pendingWorksheetCodes.delete(code)
  })
  pendingWorksheetCodes.set(code, pending)
  return pending
}
