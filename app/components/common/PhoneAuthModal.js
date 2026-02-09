let PhoneAuthModal
const PhoneAuthModalComponent = Vue.extend(require('./PhoneAuthModal.vue').default)
const ModalView = require('views/core/ModalView')
const RecoverModal = require('views/core/RecoverModal')
const store = require('core/store')
const silentStore = { commit: _.noop, dispatch: _.noop }

module.exports = (PhoneAuthModal = (function () {
  PhoneAuthModal = class PhoneAuthModal extends ModalView {
    static initClass () {
      this.prototype.id = 'phone-auth-modal'
      this.prototype.template = require('templates/core/phone-auth-modal')
      this.prototype.VueComponent = PhoneAuthModalComponent
      this.prototype.hidesTeam = false
    }

    render () {
      super.render()
      this.afterRender()
      return this
    }

    onLoaded () { return this.render() }

    afterRender () {
      if (this.vueComponent) {
        this.$el.find('#phone-auth-modal-pug').replaceWith(this.vueComponent.$el)
      } else {
        if (this.vuexModule) {
          if (!_.isFunction(this.vuexModule)) {
            throw new Error('@vuexModule should be a function')
          }
          store.registerModule('page', this.vuexModule())
        }

        this.vueComponent = new this.VueComponent({
          el: this.$el.find('phone-auth-modal-pug')[0],
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
        this.vueComponent.$on('open-recover-modal', () => {
          this.openModalView(new RecoverModal())
        })
      }
      return super.afterRender(...arguments)
    }

    destroy () {
      if (this.vuexModule) {
        store.unregisterModule('page')
      }
      this.vueComponent.$destroy()
      this.vueComponent.$store = silentStore
    }
  }
  PhoneAuthModal.initClass()
  return PhoneAuthModal
})())
