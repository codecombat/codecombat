import { getThang, getThangTypeOriginal } from '../../../app/core/api/thang-types'
import {
  getBackgroundSlug,
  getBackgroundObject,
  getRightCharacterThangTypeSlug,
  getLeftCharacterThangTypeSlug,
  getHeroPet
} from '../../../app/schemas/models/selectors/cinematic'
import { HERO_THANG_ID } from './constants'

/**
 * @typedef {import('../../../app/schemas/models/selectors/cinematic')} Cinematic
 */

const ThangType = require('models/ThangType')

/**
 * Loader loads resources and stores them in a Map.
 * Thus the loader caches resources that have already been requested.
 */

export default class Loader {
  constructor ({ data }) {
    this.data = data
    // Stores thangType with slug or original as the key.
    this.loadedThangTypes = new Map()
    // Stores the thangType loading promise with slug or original as key.
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
   *
   * If an admin or player doesn't have a hero, falls back to a default.
   */
  loadPlayerThangType () {
    const original = (me.get('ozariaHeroConfig') || {}).cinematicThangTypeOriginal || HERO_THANG_ID

    this.loadingThangTypes.set(
      original,
      (async () => {
        const attr = await getThangTypeOriginal(original)
        this.loadedThangTypes.set(original, new ThangType(attr))
      })()
    )
  }

  /**
   * Queues up the background objects
   * @param {Shot[]} shots
   */
  loadBackgroundObjects (shots) {
    shots
      .filter(shot => (shot.dialogNodes || []).length > 0)
      .forEach(({ dialogNodes }) =>
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
        const heroPetSlug = (getHeroPet(shot) || {}).slug
        if (heroPetSlug) {
          slugs.push(heroPetSlug)
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
      (async () => {
        const attr = await getThang({ slug })
        this.loadedThangTypes.set(slug, new ThangType(attr))
      })()
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
