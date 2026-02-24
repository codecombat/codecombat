import { Popup as CookieConsentPopup } from 'cookieconsent'
import 'cookieconsent/build/cookieconsent.min.css'

import BaseTracker from './BaseTracker'

/**
 * Not a true tracker in that this tracker does not report data but instead
 * prompts the user to consent to tracking.  It shares the same initialization
 * and event emitter characteristics of a tracker.
 */
export default class CookieConsentTracker extends BaseTracker {
  constructor (store) {
    super()

    this.store = store
  }

  /**
   * Requires that user locale has already been loaded on the page
   */
  _initializeTracker () {
    const preferredLocale = this.store.getters['me/preferredLocale']
    const preferredLocaleLoaded = this.store.getters.localeLoaded(preferredLocale)

    if (!preferredLocaleLoaded) {
      console.error('Preferred locale not loaded for user. This will result in consent tracker showing in incorrect language.')
    }

    if (me.isStudent() || window.features?.china) {
      this.onInitializeSuccess()
      return
    }

    // For logged-in users, sync consent from user account to browser cookie
    this.syncConsentFromUserAccount()

    // Show cookie consent globally for all users to comply with privacy laws worldwide
    this.store.watch(
      (state, getters) => getters['me/preferredLocale'],
      () => this.onPreferredLocaleChanged()
    )

    this.initializeCookieConsent()
    this.onInitializeSuccess()
  }

  syncConsentFromUserAccount () {
    const savedConsent = me.getLatestCookieConsent()
    if (savedConsent && savedConsent.action) {
      // Set the browser cookie to match user's saved preference.
      // Use direct cookie manipulation rather than cookieconsent.utils.setCookie,
      // which is an undocumented internal API that may not exist (see User.js:clearCookieConsent).
      // [TODO] if the API does exist, we should use it instead. Also, a very old package!
      const expiry = new Date()
      expiry.setFullYear(expiry.getFullYear() + 1)
      document.cookie = `cookieconsent_status=${savedConsent.action}; expires=${expiry.toUTCString()}; path=/`
      // Update store immediately
      this.store.dispatch('tracker/cookieConsentStatusChange', savedConsent.action)
    }
  }

  onInitialise (status) {
    // Called on page load when a returning user already has a consent cookie.
    // Only sync the store — do not save to the server, as nothing has changed.
    this.log('CookieConsent onInitialise - status:', status)
    this.store.dispatch('tracker/cookieConsentStatusChange', status)
  }

  onStatusChange (status) {
    // Called when the user actively changes consent via the banner.
    this.log('CookieConsent onStatusChange - status:', status)
    this.store.dispatch('tracker/cookieConsentStatusChange', status)

    me.saveCookieConsent(status, 'User cookie consent from banner')
    me.save(null, {
      error: (_res, error) => {
        console.error('Failed to save cookie consent to user account', error)
      },
    })
  }

  onPreferredLocaleChanged () {
    const preferredLocale = this.store.getters['me/preferredLocale']
    const preferredLocaleLoaded = this.store.getters.localeLoaded(preferredLocale)

    if (preferredLocaleLoaded) {
      this.initializeCookieConsent()
    } else {
      const unsubscribe = this.store.watch(
        (state, getters) => getters.localeLoaded(preferredLocale),
        () => {
          unsubscribe()
          this.initializeCookieConsent()
        }
      )
    }
  }

  initializeCookieConsent () {
    if (this.popup) {
      this.popup.destroy()
      this.popup = undefined
    }

    this.popup = new CookieConsentPopup({
      // Note the currently released version of cookieconsent has a bug that
      // prevents onInitialise from being called when the popup is loaded
      // before the user has interacted.
      onInitialise: this.onInitialise.bind(this),

      onStatusChange: this.onStatusChange.bind(this),

      container: document.body,

      palette: {
        popup: { background: '#000' },
        button: { background: '#7a65fc', text: '#ffffff' },
      },

      hasTransition: false,
      revokeable: true,
      law: false,
      location: false,
      type: 'opt-in',

      content: {
        allow: Vue.t('legal.cookies_allow'),
        message: Vue.t('legal.cookies_message'),
        dismiss: Vue.t('general.accept'),
        deny: Vue.t('legal.cookies_deny'),
        link: Vue.t('nav.privacy'),
        href: '/privacy',
      },
    })
  }
}
