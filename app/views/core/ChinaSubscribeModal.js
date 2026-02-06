let ChinaSubscribeModal
const ChinaSubscribeModalComponent = Vue.extend(require('./ChinaSubscribeComponent.vue').default)
const ModalView = require('views/core/ModalView')
const store = require('core/store')
const silentStore = { commit: _.noop, dispatch: _.noop }
const Products = require('collections/Products')
const CreateAccountModal = require('views/core/CreateAccountModal')
const utils = require('core/utils')

const wechatPay = require('core/api/wechat')
const WechatPayModal = require('./WechatPayModal.js').default

module.exports = (ChinaSubscribeModal = (function () {
  ChinaSubscribeModal = class ChinaSubscribeModal extends ModalView {
    static initClass () {
      this.prototype.id = 'china-subscribe-modal'
      this.prototype.template = require('templates/core/china-subscribe-modal')
      this.prototype.VueComponent = ChinaSubscribeModalComponent
      this.prototype.hidesTeam = false
    }

    constructor (options) {
      if (options == null) { options = {} }
      super(options)
      this.couponID = utils.getQueryVariable('coupon')
      this.products = new Products()
      const data = {}
      if (this.couponID) {
        data.coupon = this.couponID
      }
      this.supermodel.trackRequest(this.products.fetch({ data }))
    }

    render () {
      super.render()
      this.afterRender()
      return this
    }

    onLoaded () {
      this.basicProduct = this.products.getBasicSubscriptionForUser(me)
      this.basicProductAnnual = this.products.getBasicAnnualSubscriptionForUser()
      if (features.chinaHome) {
        this.seasonalProduct = this.products.getChinaSeasonlySubscriptionForUser()
      }
      return this.render()
    }

    afterRender () {
      if (this.vueComponent) {
        this.$el.find('#china-subscribe-modal').replaceWith(this.vueComponent.$el)
      } else {
        if (this.vuexModule) {
          if (!_.isFunction(this.vuexModule)) {
            throw new Error('@vuexModule should be a function')
          }
          store.registerModule('page', this.vuexModule())
        }

        this.vueComponent = new this.VueComponent({
          el: this.$el.find('#china-subscribe-modal')[0],
          propsData: this.propsData,
          store,
          provide: {
            openLegacyModal: this.openModalView.bind(this),
            legacyModalClosed: this.modalClosed.bind(this),
          },
        })
        this.vueComponent.$mount()
        this.vueComponent.$on('close', () => {
          this.hide()
        })
        this.vueComponent.$on('season', () => {
          this.wechatPayMethod(this.seasonalProduct)
        })

        this.vueComponent.$on('month', () => {
          this.wechatPayMethod(this.basicProduct)
        })
        this.vueComponent.$on('year', () => {
          this.wechatPayMethod(this.basicProductAnnual)
        })
      }
      return super.afterRender(...arguments)
    }

    wechatPayMethod (product) {
      if (!product) return
      if (me.get('anonymous')) {
        const PhoneAuthModal = require('components/common/PhoneAuthModal.js')
        if (features?.chinaHome) {
          return this.openModalView(new PhoneAuthModal())
        }
        return this.openModalView(new CreateAccountModal({ startOnPath: 'individual', subModalContinue: 'monthly' }))
      }
      wechatPay.pay(product.get('planID')).then((res) => {
        this.openModalView(new WechatPayModal({ propsData: { url: res.wechat.code_url, sessionId: res.sessionId } }))
      })
    }

    destroy () {
      if (this.vuexModule) {
        store.unregisterModule('page')
      }
      this.vueComponent.$destroy()
      this.vueComponent.$store = silentStore
    }
  }
  ChinaSubscribeModal.initClass()
  return ChinaSubscribeModal
})())
