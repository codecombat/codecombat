import VueComponentView from './VueComponentView'

import store from 'core/store'
import cocoVueRouter from 'app/core/vueRouter'

import Root from '../../components/Root'

export default class SingletonAppVueComponentView extends VueComponentView {

  constructor () {
    // For now we only support the default the default base-flat template
    super(null, {})

    // Head tag management will be performed inside of Vue app
    this.skipMetaBinding = true
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
