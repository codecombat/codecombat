import fetchJson from 'app/core/api/fetch-json'

/**
 * Retrieves the json representation of a cutscene.
 * @param {string} slugOrId - Slug or Id of the cutscene.
 * @async
 * @return {Promise<Object>} raw Cutscene object
 */
export const getCutscene = slugOrId => {
  if (!slugOrId) {
    throw new Error(`No slugOrId supplied`)
  }
  return fetchJson(`/db/cutscene/${slugOrId}`)
}

/**
 * Returns a list of all cutscenes in the database by Name and slug.
 * @async
 * @returns {Promise<Object[]>}
 */
export const getAllCutscenes = () => fetchJson('/db/cutscene?project=slug,name')

/**
 * Updates a cutscene in the database.
 * @async
 * @returns {Promise<Object>} raw Cutscene object
 */
export const putCutscene = ({ data }, options = {}) => {
  if (!data) {
    throw new Error('Please pass in a data property.')
  }
  const slugOrId = data.id || data.slug
  if (!slugOrId) {
    throw new Error('You must pass either a slug or ObjectId')
  }
  return fetchJson(`/db/cutscene/${slugOrId}`, _.assign({}, options, {
    method: 'PUT',
    json: data
  }))
}

/**
 * Creates a new cutscene in the database.
 * @async
 * @returns {Promise<Object>} raw Cutscene object
 */
export const createCutscene = ({ name }, options = {}) =>
  fetchJson('/db/cutscene', _.assign({}, options, {
    method: 'POST',
    json: { name }
  }))
