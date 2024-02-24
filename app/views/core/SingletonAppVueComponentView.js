import VueComponentView from './VueComponentView'

import store from 'core/store'
import cocoVueRouter from 'app/core/vueRouter'

import Root from '../../components/Root'

const utils = require('core/utils')
const CreateAccountModal = require('views/core/CreateAccountModal/CreateAccountModal')
const MineModal = require('views/core/MineModal') // Roblox modal
const storage = require('core/storage')




export default class SingletonAppVueComponentView extends VueComponentView {

  constructor () {
    // For now we only support the default the default base-flat template
    super(null, {})

    // Head tag management will be performed inside of Vue app
    this.skipMetaBinding = true
  }


  afterRender () {
    if (me.isAnonymous()) {
      if ((document.location.hash === '#create-account') || (utils.getQueryVariable('registering') === true)) {
        _.defer(() => { if (!this.destroyed) { return this.openModalView(new CreateAccountModal()) } })
      }
      if (document.location.hash === '#create-account-individual') {
        _.defer(() => { if (!this.destroyed) { return this.openModalView(new CreateAccountModal({ startOnPath: 'individual' })) } })
      }
      if (document.location.hash === '#create-account-home') {
        _.defer(() => { if (!this.destroyed) { return this.openModalView(new CreateAccountModal({ startOnPath: 'individual-basic' })) } })
      }
      if (document.location.hash === '#create-account-student') {
        _.defer(() => { if (!this.destroyed) { return this.openModalView(new CreateAccountModal({ startOnPath: 'student' })) } })
      }
      if (document.location.hash === '#create-account-teacher') {
        _.defer(() => { if (!this.destroyed) { return this.openModalView(new CreateAccountModal({ startOnPath: 'teacher' })) } })
      }
      if (utils.getQueryVariable('create-account') === 'teacher') {
        _.defer(() => { if (!this.destroyed) { return this.openModalView(new CreateAccountModal({ startOnPath: 'teacher' })) } })
      }
      if (document.location.hash === '#login') {
        const AuthModal = require('app/views/core/AuthModal')
        const url = new URLSearchParams(window.location.search)
        _.defer(() => { if (!this.destroyed) { return this.openModalView(new AuthModal({ initialValues: { email: url.get('email') } })) } })
      }
    }

    _.defer(() => { if (!storage.load('roblox-clicked') && !this.destroyed) { return this.openModalView(new MineModal()) } })

    if (utils.isCodeCombat) {
      let needle, needle1, paymentResult, title, type
      if ((needle = utils.getQueryVariable('payment-studentLicenses'), ['success', 'failed'].includes(needle)) && !this.renderedPaymentNoty) {
        paymentResult = utils.getQueryVariable('payment-studentLicenses')
        if (paymentResult === 'success') {
          title = $.i18n.t('payments.studentLicense_successful')
          type = 'success'
          if (utils.getQueryVariable('tecmilenio')) {
            title = '¡Felicidades! El alumno recibirá más información de su profesor para acceder a la licencia de CodeCombat.'
          }
          this.trackPurchase(`Student license purchase ${type}`)
        } else {
          title = $.i18n.t('payments.failed')
          type = 'error'
        }
        noty({ text: title, type, timeout: 10000, killer: true })
        this.renderedPaymentNoty = true
      } else if ((needle1 = utils.getQueryVariable('payment-homeSubscriptions'), ['success', 'failed'].includes(needle1)) && !this.renderedPaymentNoty) {
        paymentResult = utils.getQueryVariable('payment-homeSubscriptions')
        if (paymentResult === 'success') {
          title = $.i18n.t('payments.homeSubscriptions_successful')
          type = 'success'
          this.trackPurchase(`Home subscription purchase ${type}`)
        } else {
          title = $.i18n.t('payments.failed')
          type = 'error'
        }
        noty({ text: title, type, timeout: 10000, killer: true })
        this.renderedPaymentNoty = true
      }
    } else {
      window.addEventListener('load', () => __guard__($('#core-curriculum-carousel').data('bs.carousel'), x => x.$element.on('slid.bs.carousel', function (event) {
        const nextActiveSlide = $(event.relatedTarget).index()
        const $buttons = $('.control-buttons > button')
        $buttons.removeClass('active')
        return $('[data-slide-to=\'' + nextActiveSlide + '\']').addClass('active')
      })))
    }
    return super.afterRender()
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
