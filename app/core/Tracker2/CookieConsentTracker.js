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
    const preferredLocale =  this.store.getters['me/preferredLocale']
    const preferredLocaleLoaded = this.store.getters['localeLoaded'](preferredLocale)

    if (!preferredLocaleLoaded) {
      console.error('Preferred locale not loaded for user, this will result in consent tracker showing in incorrect language.')
    }

    if (!this.store.getters['me/inEU']) {
      this.onInitializeSuccess()
      return
    }

    this.store.watch(
      (state, getters) => getters['me/preferredLocale'],
      () => this.onPreferredLocaleChanged()
   )

    this.initializeCookieConsent()
    this.onInitializeSuccess()
  }

  onStatusChange (status) {
    this.store.dispatch('tracker/cookieConsentStatusChange', status)
  }

  onPreferredLocaleChanged () {
    const preferredLocale =  this.store.getters['me/preferredLocale']
    const preferredLocaleLoaded = this.store.getters['localeLoaded'](preferredLocale)

    if (preferredLocaleLoaded) {
      this.initializeCookieConsent()
    } else {
      let unsubscribe = this.store.watch(
        (state, getters) => getters['localeLoaded'](preferredLocale),
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
        button: { background: "#f1d600"
        }
      },

      hasTransition: false,
      revokeable: true,
      law: false,
      location: false,
      type: 'opt-out',

      content: {
        allow: Vue.t('legal.cookies_allow'),
        message: Vue.t('legal.cookies_message'),
        dismiss: Vue.t('general.accept'),
        deny: Vue.t('legal.cookies_deny'),
        link: Vue.t('nav.privacy'),
        href: '/privacy'
      }
    })
  }
}
