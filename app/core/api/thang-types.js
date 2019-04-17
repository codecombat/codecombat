const fetchJson = require('./fetch-json')
const _ = require('lodash')

/**
 * @typedef getThangOptions
 * @type {object}
 * @property {string} slug - The slug of the thangtype
 * @property {string[]} [projection] - Projections that can be applied.
 */

/**
 * Retrieves a thangType from the database.
 * @param {getThangOptions} options - Support projection field with a list of string attributes.
 */
export const getThang = (options = {}) => {
  const data = {}

  if (options.project && Array.isArray(options.project)) {
    _.assign(data, {
      project: options.project.join(',')
    })
  }
  if (!options.slug) {
    throw new Error('You must pass a \'slug\' property into getThang function')
  }
  return fetchJson(`/db/thang.type/${options.slug}`, { data })
}

export const getHeroes = (options) => {
  const data = {
    view: 'heroes'
  }
  if (options && options.project) {
    _.assign(data, {
      project: options.project.join(',')
    })
  }
  return fetchJson('/db/thang.type', { data })
}
