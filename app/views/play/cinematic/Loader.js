import { get } from 'core/api/cinematic'
import { getThang } from '../../../core/api/thang-types'

/**
 * @typedef {import('../../../schemas/selectors/cinematic')} Cinematic
 */

const ThangType = require('models/ThangType')

/**
 * Loader loads resources and stores them in a Map.
 * Thus the loader caches resources that have already been requested.
 */

export default class Loader {
  constructor ({ slug }) {
    this.slug = slug

    // Stores thangType with slug as the key.
    this.loadedThangTypes = new Map()
    // Stores the thangType loading promise with slug as key.
    this.loadingThangTypes = new Map()
  }

  /**
   * Fetches initial Cinematic data and loads the ThangTypes.
   * @returns {Cinematic} The raw JSON object with Cinematic data.
   */
  async loadAssets () {
    this.data = await get(this.slug)
    this.loadThangTypes(this.data.shots)
    await this.load()
    return this.data
  }

  /**
   * Iterate through the shotSetups and start loading the required thangTypes.
   * Doesn't block until `load` method is called.
   *
   * TODO: Add retry logic to the getThang function.
   */
  loadThangTypes (shots) {
    const characterArray = []
    shots
      .map(({ shotSetup }) => shotSetup)
      .filter(setup => setup)
      .forEach(({ leftThangType, rightThangType }) => {
        if (leftThangType) {
          characterArray.push(leftThangType)
        }
        if (rightThangType) {
          characterArray.push(rightThangType)
        }
      })
    // Now we have a list of only character objects, we can fetch the data,
    // storing the promise in our `loadedThangTypes` Map.
    characterArray
      .filter(character => character)
      .filter(({ type = undefined }) => typeof type === 'object' && type !== undefined)
      .filter(({ type: { slug } }) => !(this.loadedThangTypes.has(slug) || this.loadingThangTypes.has(slug)))
      .map(({ type: { slug } }) => slug)
      .forEach(slug =>
        this.loadingThangTypes.set(
          slug,
          getThang({ slug })
            .then(attr => new ThangType(attr))
            .then(t => this.loadedThangTypes.set(slug, t))
        ))
  }

  /**
   * Ensure all ThangTypes in `loadingThangTypes` complete loading.
   */
  async load () {
    // Need at least one promise in loadingPromises to prevent empty array Promise bug.
    const loadingPromises = [Promise.resolve()]
    this.loadingThangTypes.forEach((value) => {
      loadingPromises.push(value)
    })
    await Promise.all(loadingPromises)
    this.loadingThangTypes = new Map()
  }

  /**
   * Get a loaded thangType by slug.
   * @param {string} slug - Slug of a thangType
   */
  getThangType (slug) {
    const thangType = this.loadedThangTypes.get(slug)
    if (!thangType) {
      throw new Error(`Make sure '${slug}' thangType is loaded before getting`)
    }
    return thangType
  }
}
