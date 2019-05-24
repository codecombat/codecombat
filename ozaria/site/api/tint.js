import fetchJson from 'app/core/api/fetch-json'

/**
 * Updates a Tint in the database.
 * @async
 * @returns {Object} Tint object
 */
export const putTint = ({ data }, options = {}) => {
  if (!data) {
    throw new Error('Please pass in a data property.')
  }
  const slugOrId = data.id || data.slug
  if (!slugOrId) {
    throw new Error('You must pass either a slug or ObjectId')
  }
  return fetchJson(`/db/tint/${slugOrId}`, _.assign({}, options, {
    method: 'PUT',
    json: data
  }))
}
