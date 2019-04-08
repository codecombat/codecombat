const fetchJson = require('./fetch-json')
const _ = require('lodash')

/**
 * @typedef getThangOptions
 * @type {object}
 * @property {string} slug - The slug of the thangtype
 * @property {string[]} [projection] - Projections that can be applied.
 */

/**
 * Retrieves a thang from the database.
 * @param {getThangOptions} options - Support projection field with a list of string attributes.
 */
export const getThang = async options => {
  const data = {}
  if (options.project) {
    _.assign(data, {
      project: options.project.join(',')
    })
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
