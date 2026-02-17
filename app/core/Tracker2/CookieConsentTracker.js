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
      // Set the browser cookie to match user's saved preference
      const cookieConsentLib = require('cookieconsent')
      const util = cookieConsentLib.utils || {}
      if (util.setCookie) {
        util.setCookie('cookieconsent_status', savedConsent.action, 365, '', '/')
      }
      // Update store immediately
      this.store.dispatch('tracker/cookieConsentStatusChange', savedConsent.action)
    }
  }

  onStatusChange (status) {
    this.log('CookieConsent onStatusChange - status:', status)
    this.store.dispatch('tracker/cookieConsentStatusChange', status)

    me.saveCookieConsent(status, 'User cookie consent from banner')
    me.save(null, {
      error: (error) => {
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
      onInitialise: this.onStatusChange.bind(this),

      onStatusChange: this.onStatusChange.bind(this),

      container: document.body,

      palette: {
        popup: { background: '#000' },
        button: { background: '#7a65fc' },
        buttonText: { color: '#ffffff' },
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
