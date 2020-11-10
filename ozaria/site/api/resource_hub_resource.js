import fetchJson from 'app/core/api/fetch-json'

/**
 * Creates a new resource in the database.
 * @async
 */
export const createNewResourceHubResource = ({ name, ...opts }, options = {}) =>
  fetchJson('/db/resource_hub_resource', _.assign({}, options, {
    method: 'POST',
    json: { name, ...opts }
  }))

export const getResourceHubResources = () => fetchJson('/db/resource_hub_resource')
