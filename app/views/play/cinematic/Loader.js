import { get } from 'core/api/cinematic'
import { getThang } from '../../../core/api/thang-types'

const ThangType = require('models/ThangType')


/**
 * Loader loads resources and stores them in a map.
 * Thus the loader caches resources that have been fetched.
 */

export default class Loader {
  constructor ({ slug }) {
    this.slug = slug

    // Stores thangTypes
    this.loadedThangTypes = new Map()
    this.loadingThangTypes = new Map()
  }

  /**
   * Fetches initial data and loads all the other data required.
   */
  async loadAssets () {
    this.data = await get(this.slug)
    console.log('Success we have data.', this.data)
    this.loadThangTypes(this.data.shots)
    await this.load()
    console.log(`have thangTypes: `, this.loadedThangTypes)
    return this.data
  }

  /**
   * Iterates through the shotSetups and starts loading the thangTypes.
   * Doesn't block until `load` method is called.
   *
   * TODO: Add retry logic to the getThang function.
   */
  loadThangTypes (shots) {
    const characterArray = []
    shots
      .map(shot => shot.shotSetup)
      .filter(setup => setup)
      .forEach(({ leftThangType, rightThangType }) => {
        if (leftThangType) {
          characterArray.push(leftThangType)
        }
        if (rightThangType) {
          characterArray.push(rightThangType)
        }
      })

    characterArray
      .filter(character => character)
      .filter(({ type = undefined, slug = undefined }) => type === 'slug' && slug)
      .filter(({ slug }) => !(this.loadedThangTypes.has(slug) || this.loadingThangTypes.has(slug)))
      .map(({ slug }) => slug)
      .forEach(slug =>
        this.loadingThangTypes.set(
          slug,
          getThang({ slug })
            .then(attr => new ThangType(attr))
            .then(t => this.loadedThangTypes.set(slug, t))
            .then(() => console.log(`LOADED ThangType`, slug))
        ))
  }

  /**
   * Load all resources.
   */
  async load () {
    const loadingPromises = [Promise.resolve()]
    this.loadingThangTypes.forEach((value) => {
      loadingPromises.push(value)
    })
    await Promise.all(loadingPromises)
    this.loadingThangTypes = new Map()
  }

  /**
   * Gets a loaded thangType by slug.
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
