import BaseTracker from './BaseTracker'
import { initSuperflow } from '@usesuperflow/client'
import { getQueryVariable } from '../utils'

export default class SuperflowTracker extends BaseTracker {
  constructor (store) {
    super()

    this.store = store
  }

  get isSuperflowEnabled () {
    return getQueryVariable('review')
  }

  loadSuperflow () {
    initSuperflow('B57Yo9pQHtSLyn2fhVln')
  }

  async _initializeTracker () {
    if (this.isSuperflowEnabled) {
      await this.loadSuperflow()
    }
    this.onInitializeSuccess()
  }
}
