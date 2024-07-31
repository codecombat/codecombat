import fetchJson from 'app/core/api/fetch-json'

export const createNewAIJuniorProject = ({ ...opts }, options = {}) =>
  fetchJson('/db/ai_junior_project', _.assign({}, options, {
    method: 'POST',
    json: { ...opts }
  }))

export const processAIJuniorProject = ({ projectHandle, ...opts }, options = {}) =>
  fetchJson(`/db/ai_junior_project/${projectHandle}/process`, _.assign({}, options, {
    method: 'POST',
    json: { ...opts }
  }))

export const getAIJuniorProjects = (options = {}) => fetchJson('/db/ai_junior_project', options)

export const getAIJuniorProject = ({ projectHandle }, options = {}) => fetchJson(`/db/ai_junior_project/${projectHandle}`, options)

export const getAIJuniorProjectsForScenarioAndUser = ({ scenarioHandle, userId }, options = {}) => fetchJson(`/db/ai_junior_project?scenarioHandle=${scenarioHandle}&userId=${userId}`, options)
