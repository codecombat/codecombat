import EventEmitter from 'events'

/**
 * A baseline tracker that:
 *   1. Defines a standard initialization flow for all trackers
 *   2. Exposes an event emitter interface for all trackers
 *   3. Exposes a default tracker interface with a noop implementation.
 *
 * Standard initialization flow:
 * The standard initialization flow is based around the this.initializationComplete promise
 * that is exposed publicly by the tracker.  This promise should be resolved by the tracker
 * by calling this.onInitializationSuccess (or this.onInitializationError) when the
 * initialization process has been completed (or failed).  The initializationComplete
 * promise should _never_ be overwritten as other external components can depend on it.
 */
export default class BaseTracker extends EventEmitter {
  constructor () {
    super()

    this.initializing = false
    this.initialized = false

    this.setupInitialization()
  }

  async identify (traits = {}) {}

  async trackPageView (includeIntegrations = {}) {}

  async trackEvent (action, properties = {}, includeIntegrations = {}) {}

  async trackTiming (duration, category, variable, label) {}

  get isInitialized () {
    return this.initialized
  }

  set isInitialized (initialized) {
    return this.initialized = initialized
  }

  get isInitializing () {
    return this.initializing
  }

  set isInitializing (initializing) {
    return this.initializing = initializing
  }

  get initializationComplete () {
    return this.initializationCompletePromise
  }

  /**
   * Standard initialization method to be used to initialize the tracker.  Ensures that the
   * initialize process is only called once and returns the initializationComplete promise.
   *
   * Calls internal initialize method
   */
  async initialize () {
    if (this.isInitializing) {
      return this.initializationComplete
    }

    this.isInitializing = true

    await this._initializeTracker()

    return this.initializationComplete
  }

  /**
   * Internal tracker initialization method to be implemented by sub trackers.  This is
   * called by the initialize method when the tracker is initialized.
   *
   * This method _must_ call onInitializeSuccess or onInitializeFail
   */
  async _initializeTracker () {
    this.onInitializeSuccess()
  }

  /**
   * Sets up initialization callbacks and top level promise so that
   * all internal methods can wait on an internal initialize promise.
   *
   * This must be called from constructor _before_ initialize is called.
   */
  setupInitialization () {
    const finishInitialization = (result) => {
      this.isInitialized = result

      delete this.onInitializeSuccess
      delete this.onInitializeFail
    }

    this.initializationCompletePromise = new Promise((resolve, reject) => {
      this.onInitializeSuccess = () => {
        resolve()
        finishInitialization(true)
      }

      this.onInitializeFail = () => {
        reject()
        finishInitialization(false)
      }
    })
  }
}
