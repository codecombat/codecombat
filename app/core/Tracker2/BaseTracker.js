export const TRACKER_LOGGING_ENABLED_QUERY_PARAM = 'tracker_logging'

export const DEFAULT_USER_TRAITS_TO_REPORT = [
  'email', 'anonymous', 'dateCreated', 'hourOfCode', 'name', 'referrer', 'testGroupNumber', 'testGroupNumberUS',
  'gender', 'lastLevel', 'siteref', 'ageRange', 'schoolName', 'coursePrepaidID', 'role', 'firstName', 'lastName',
  'dateCreated'
]

export const DEFAULT_TRACKER_INIT_TIMEOUT = 12000

export function extractDefaultUserTraits(me) {
  return DEFAULT_USER_TRAITS_TO_REPORT.reduce((obj, key) => {
    const meAttr = me[key]
    if (typeof meAttr !== 'undefined' && meAttr !== null) {
      obj[key] = meAttr
    }

    return obj
  }, {})
}

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
export default class BaseTracker {
  constructor () {
    this.initializing = false
    this.initialized = false

    this.setupInitialization()

    this.loggingEnabled = false
    try {
      this.loggingEnabled = (new URLSearchParams(window.location.search)).has(TRACKER_LOGGING_ENABLED_QUERY_PARAM)
    } catch (e) {}

    this.trackerInitTimeout = DEFAULT_TRACKER_INIT_TIMEOUT
  }

  async identify (traits = {}) {}

  async resetIdentity () {}

  async trackPageView (includeIntegrations = []) {}

  async trackEvent (action, properties = {}, includeIntegrations = []) {}

  async trackTiming (duration, category, variable, label) {}

  watchForDisableAllTrackingChanges (store) {
    this.disableAllTracking = store.getters['tracker/disableAllTracking']

    store.watch(
      (state, getters) => getters['tracker/disableAllTracking'],
      (result) => { this.disableAllTracking = result }
    )
  }

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

    const initTimeout = new Promise((resolve, reject) => {
      setTimeout(() => reject(new Error('Tracker init timeout')), this.trackerInitTimeout)
    })

    try {
      await Promise.race([initTimeout, this._initializeTracker()])
    } catch (e) {
      this.onInitializeFail(e)
    }

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

      // We only want to resolve / reject the init promise once during the initialization flow.  Because some trackers
      // do not support reporting "failures" we need to support timeouts that can result in race conditions in some
      // situations.  In these situations we use the first success / fail callback to determine the tracker state and
      // we change the callbacks to noops to prevent later calls from changing the init state.
      this.onInitializeSuccess = () => {}
      this.onInitializeFail = () => {}
    }

    this.initializationCompletePromise = new Promise((resolve, reject) => {
      this.onInitializeSuccess = () => {
        resolve()
        finishInitialization(true)
      }

      this.onInitializeFail = (e) => {
        reject(e)
        finishInitialization(false)
      }
    })
  }

  log (...args) {
    if (!this.loggingEnabled) {
      return
    }

    console.info(`[tracker] [${this.constructor.name}]`, ...args)
  }
}
