import fetchJson from 'app/core/api/fetch-json'

/**
 * Retrieves the json representation of an interactive.
 * @param {string} idOrSlug - Id/Slug of the interactive.
 * @return {Promise<Object>} - Raw Interactive object
 */
export const getInteractive = idOrSlug => {
  if (!idOrSlug) {
    throw new Error(`No slug/id supplied`)
  }
  return fetchJson(`/db/interactive/${idOrSlug}`)
}

/**
 * @typedef {Object} InteractiveList
 * @param {string} name - The name of the Interactive
 * @param {string} slug - The Interactive's slug
 * @param {string} interactiveType - The interactive type
 */

/**
 * Returns a list of all interactives in the database.
 * @returns {Promise<InteractiveList[]>} - List of interactives
 */
export const getAllInteractives = () => fetchJson('/db/interactives')

/**
 * Updates an interactive in the database.
 * @returns {Promise<Object>} - Raw Interactive object
 */
export const putInteractive = ({ data }, options = {}) => {
  if (!data) {
    throw new Error('Please pass in a data property.')
  }
  const slugOrId = data.id || data.slug
  if (!slugOrId) {
    throw new Error('You must pass either a slug or ObjectId')
  }
  return fetchJson(`/db/interactive/${slugOrId}`, _.assign({}, options, {
    method: 'PUT',
    json: data
  }))
}

/**
 * Creates a new interactive in the database.
 * @returns {Promise<Object>} - Raw Interactive object
 */
export const postInteractive = ({ name }, options = {}) => {
  return fetchJson('/db/interactive', _.assign({}, options, {
    method: 'POST',
    json: { name }
  }))
}

/**
 * Retrieves the json representation of interactive session.
 * @param {string} idOrSlug - Id/Slug of the interactive.
 * @param {'javascript'|'python'} options.codeLanguage - interactive session language
 * @return {Promise<Object>} - Raw Interactive Session object
 */
export const getSession = (idOrSlug, options = {}) => {
  if (!idOrSlug) {
    throw new Error(`No slug/id supplied`)
  }
  return fetchJson(`/db/interactive/${idOrSlug}/session`, {
    method: 'GET',
    data: options
  })
}

/**
 * Puts an interactive session into the database
 * @param {string} idOrSlug - Interactive id or slug
 * @param {Object} options.json.submission - Interactive submissions
 * @param {'javascript'|'python'} options.json.codeLanguage - session language
 */
export const putSession = (idOrSlug, options = {}) => {
  if (!idOrSlug) {
    throw new Error(`No slug/id supplied`)
  }
  if (!(options.json || {}).codeLanguage) {
    throw new Error(`CodeLanguage required to post interactive submission`)
  }
  if (!(options.json || {}).submission) {
    throw new Error(`Need to post a submission`)
  }

  return fetchJson(`/db/interactive/${idOrSlug}/submission`, {
    method: 'POST',

    ...options
  })
}
