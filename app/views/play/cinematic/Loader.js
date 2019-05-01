import { getThang, getThangTypeOriginal } from '../../../core/api/thang-types'
import { getBackgroundSlug, getBackgroundObject, getRightCharacterThangTypeSlug, getLeftCharacterThangTypeSlug } from '../../../schemas/selectors/cinematic';

/**
 * @typedef {import('../../../schemas/selectors/cinematic')} Cinematic
 */

const ThangType = require('models/ThangType')

/**
 * Loader loads resources and stores them in a Map.
 * Thus the loader caches resources that have already been requested.
 */

export default class Loader {
  constructor ({ data }) {
    this.data = data
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
    this.loadThangTypes(this.data.shots)
    this.loadPlayerThangType()
    this.loadBackgroundObjects(this.data.shots)
    await this.load()
    return this.data
  }

  /**
   * Loads the player thangType from the global `me` object if accessible.
   * Has a side effect of storing the players thangType by original as a resource.
   */
  loadPlayerThangType () {
    if ((me || {}) && !me.get('heroConfig')) {
      return
    }
    const original = me.get('heroConfig').thangType
    if (!original) {
      return
    }

    this.loadingThangTypes.set(
      original,
      getThangTypeOriginal(original)
        .then(attr => new ThangType(attr))
        .then(t => this.loadedThangTypes.set(original, t))
    )
  }

  /**
   * Queues up the background objects
   * @param {Shot[]} shots
   */
  loadBackgroundObjects (shots) {
    shots
      .filter(shot => (shot.dialogNodes || []).length > 0)
      .map(({ dialogNodes }) =>
        dialogNodes
          .map(dialogNode => getBackgroundObject(dialogNode))
          .filter(bgObject => bgObject)
          .map(({ type: { slug } }) => slug)
          .filter(slug => slug)
          .forEach(slug => this.queueThangType(slug))
      )
  }

  /**
   * Iterate through the shotSetups and start loading the required thangTypes.
   * Doesn't block until `load` method is called.
   *
   * TODO: Add retry logic to the getThang function.
   */
  loadThangTypes (shots) {
    const slugs = []
    shots
      .forEach(shot => {
        const { slug } = getLeftCharacterThangTypeSlug(shot) || {}
        if (slug) {
          slugs.push(slug)
        }
        const { slug: slug2 } = getRightCharacterThangTypeSlug(shot) || {}
        if (slug2) {
          slugs.push(slug2)
        }

        const backgroundSlug = getBackgroundSlug(shot) || {}
        if (backgroundSlug) {
          slugs.push(backgroundSlug)
        }
      })
    // Now we have a list of only slugs, we can fetch the data,
    // storing the promise in our `loadedThangTypes` Map.
    slugs
      .filter(character => character)
      .filter(slug => typeof slug === 'string')
      .filter(slug => !(this.loadedThangTypes.has(slug) || this.loadingThangTypes.has(slug)))
      .forEach(slug => this.queueThangType(slug))
  }

  /**
   * Queues a ThangType resource for async loading.
   * @param {string} slug ThangType slug.
   */
  queueThangType (slug) {
    this.loadingThangTypes.set(
      slug,
      getThang({ slug })
        .then(attr => new ThangType(attr))
        .then(t => this.loadedThangTypes.set(slug, t))
    )
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
   * @returns {object|undefined} May return thangType or undefined
   */
  getThangType (slug) {
    const thangType = this.loadedThangTypes.get(slug)
    if (!thangType) {
      console.error(`Make sure '${slug}' thangType is loaded before getting`)
      return
    }
    return thangType
  }
}
