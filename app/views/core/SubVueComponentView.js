
// This is the base backbone view to render any VueComponent.
// Pass the vue component, propsData, base template into the constructor

import CocoView from 'views/core/CocoView'
import store from 'core/store'

const silentStore = { commit: _.noop, dispatch: _.noop }

export default class VueComponentView extends CocoView {
  constructor (options) {
    super(options)

    if (!this.VueComponent) {
      throw new Error('Class must be initialized with VueComponent')
    }

    this.props = {}
  }

  getMountPoint() {
    return this.$el[0]
  }

  buildVueComponent() {
    return new this.VueComponent({
      el: this.getMountPoint(),
      propsData: this.props,
      store: store
    })
  }

  setState (state = {})  {
    for (const key of Object.keys(state)) {
      Vue.set(
        this.props,
        key,
        state[key]
      )
    }
  }

  afterRender() {
    if (!this.vueComponent) {
      this.vueComponent = this.buildVueComponent()
    }

    this.props = this.vueComponent.$props

    super.afterRender()
  }

  destroy() {
    super.destroy()

    this.vueComponent.$destroy()
    this.vueComponent.$store = silentStore
  }
}
