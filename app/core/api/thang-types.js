import fetchJson from './fetch-json'
import _ from 'lodash'

/**
 * @typedef getThangOptions
 * @type {object}
 * @property {string} slug - The slug of the thangtype
 * @property {string[]} [projection] - Projections that can be applied.
 */

/**
 * Retrieves a thangType from the database.
 * @param {getThangOptions} options - Support projection field with a list of string attributes.
 * @async
 * @returns {Promise<Object>} - the ThangType object
 */
export const getThang = (options = {}) => {
  const data = {}

  if (!options.slug) {
    throw new Error('You must pass a \'slug\' property into getThang function')
  }

  if (options.project && Array.isArray(options.project)) {
    _.assign(data, {
      project: options.project.join(',')
    })
  }

  return fetchJson(`/db/thang.type/${options.slug}`, { data })
}

/**
 * Retrieves a thangType from the database by original.
 * @param {string} original The ThangType original
 * @async
 * @returns {Promise<Object>} - the ThangType object
 */
export const getThangTypeOriginal = original => {
  if (!original) {
    throw new Error('You must pass an \'original\' property into getThangOriginal')
  }
  return fetchJson(`/db/thang.type/${original}/version`)
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
