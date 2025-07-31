import VueComponentView from './VueComponentView'

import store from 'core/store'
import cocoVueRouter from 'app/core/vueRouter'

import Root from '../../components/Root'

const utils = require('core/utils')
let inProgressAuth = false

export default class SingletonAppVueComponentView extends VueComponentView {

  constructor () {
    // For now we only support the default the default base-flat template
    super(null, {})

    // Head tag management will be performed inside of Vue app
    this.skipMetaBinding = true
  }


  afterRender () {
    this.setupHashHandlers()
    return super.afterRender()
  }

  async setupHashHandlers(){
    let modalOpened = false
    const autoAuth = utils.getQueryVariable('auto-auth')

    if (me.isAnonymous()) {
      const hash = document.location.hash
      const registering = utils.getQueryVariable('registering')
      const createAccount = utils.getQueryVariable('create-account')

      const paths = {
        '#create-account': null,
        '#create-account-individual': 'individual',
        '#create-account-home': 'individual-basic',
        '#create-account-student': 'student',
        '#create-account-teacher': 'teacher'
      }

      if ((hash === '#create-account' && registering === true) || paths[hash] || createAccount === 'teacher') {
        const startOnPath = paths[hash] || createAccount
        _.defer(() => {
          if (!this.destroyed) {
            return this.openCreateAccountModal({ startOnPath })
          }
        })
        modalOpened = true
      }

      if (hash === '#login') {
        const url = new URLSearchParams(window.location.search)
        _.defer(() => {
          if (!this.destroyed) {
            return this.openAuthModal({ initialValues: { email: url.get('email') } })
          }
        })
        modalOpened = true
      }
    }

    if ($('.ozaria-modal, .modal-dialog').length) {
      modalOpened = true
    }

    if (autoAuth) {
      if (inProgressAuth) {
        console.log('inProgressAuth', inProgressAuth)
        return
      }
      inProgressAuth = true
      try {
        await this.handleAutoAuth(autoAuth)
      } catch (e) {
        console.error(e)
      } finally {
        inProgressAuth = false
      }
    }
  }

  async handleAutoAuth (autoAuth) {
    if (!me.isAnonymous()) {
      noty({ text: $.i18n.t('library.already_logged_in'), layout: 'topCenter', type: 'warning', timeout: 5000 })
      return
    }

    let handler
    if (autoAuth === 'classlink') {
      handler = application.classlinkHandler
    } else if (autoAuth === 'schoology') {
      handler = application.schoologyHandler
    } else {
      noty({ text: `Unsupported authentication provider: ${autoAuth}`, layout: 'topCenter', type: 'error', timeout: 5000 })
      return
    }
    const { loggedIn, role, email, firstName, lastName } = await handler.logInWithEdlink()

    if (loggedIn) {
      window.location.href = '/'
    } else {
      const assumedRole = role
      const options = {
        ssoUsed: autoAuth,
        path: assumedRole,
        email,
        screen: assumedRole !== 'student' ? 'sso-confirm' : 'segment-check',
        autoName: `${email.split('@')[0]}+${autoAuth}`,
        ssoAttrs: {
          email,
        }
      }
      if (firstName) me.set('firstName', firstName)
      if (lastName) me.set('lastName', lastName)
      this.openCreateAccountModal(options)
      noty({ text: $.i18n.t('login.login_failed'), layout: 'topCenter', type: 'error', timeout: 5000, killer: false, dismissQueue: true })
    }
  }

  buildVueComponent () {
    this.router = cocoVueRouter()

    this.router.afterEach((to, from) => {
      // Fixes issue of page not scrolling to top on navigation change
      if (to.path !== from.path) {
        // If the user has navigated within the router, try and reset the scroll position.
        try {
          // Required so that jade recompiles with new variables.
          this.render()
          window.scrollTo(0, 0)
        } catch (e) {
          // Can fail silently. Handling browser compatibility
        }
      }
    })

    return new Vue({
      el: this.$el.find('#site-content-area')[0],

      store,
      router: this.router,

      render: (h) => h(Root),

      provide: {
        openLegacyModal: this.openModalView.bind(this),
        legacyModalClosed: this.modalClosed.bind(this)
      }
    })
  }
}
