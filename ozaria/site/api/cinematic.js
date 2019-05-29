import fetchJson from 'app/core/api/fetch-json'

/**
 * Retrieves the json representation of a cinematic.
 * @param {string} slug - Slug of the cinematic.
 * @async
 * @return {Promise<import('../../../app/schemas/models/selectors/cinematic').Cinematic} raw Cinematic object
 */
export const getCinematic = slug => {
  if (!slug) {
    throw new Error(`No slug supplied`)
  }
  return fetchJson(`/db/cinematic/${slug}`)
}

/**
 * @typedef {Object} CinematicName
 * @param {string} name - The name of the Cinematic
 * @param {string} slug - The Cinematic's slug
 */

/**
 * Returns a list of all cinematics in the database by Name and slug.
 * @async
 * @returns {Promise<CinematicName[]>} - Sorted by slug
 */
export const getAllCinematics = () => fetchJson('/db/cinematic/all')

/**
 * Updates a cinematic in the database.
 * @async
 * @returns {Promise<import('../../../app/schemas/models/selectors/cinematic').Cinematic>} raw Cinematic object
 */
export const putCinematic = ({ data }, options = {}) => {
  if (!data) {
    throw new Error('Please pass in a data property.')
  }
  const slugOrId = data.id || data.slug
  if (!slugOrId) {
    throw new Error('You must pass either a slug or ObjectId')
  }
  return fetchJson(`/db/cinematic/${slugOrId}`, _.assign({}, options, {
    method: 'PUT',
    json: data
  }))
}

/**
 * Creates a new cinematic in the database.
 * @async
 * @returns {Promise<import('../../../app/schemas/models/selectors/cinematic').Cinematic} raw Cinematic object
 */
export const createCinematic = ({ name }, options = {}) =>
  fetchJson('/db/cinematic', _.assign({}, options, {
    method: 'POST',
    json: { name }
  }))
