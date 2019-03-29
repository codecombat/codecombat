
// This is the base backbone view to render any VueComponent.
// Pass the vue component, propsData, base template into the constructor

import RootView from 'views/core/RootView'
import store from 'core/store'

const silentStore = { commit: _.noop, dispatch: _.noop }

module.exports = class VueComponentView extends RootView {
  constructor (component, options) {
    super(options)
    const baseTemplate = options.baseTemplate || 'base-flat'  //base template, by default using base-flat
    this.id = 'vue-component-view'
    this.template = require('templates/'+ baseTemplate)
    this.VueComponent = component
    this.propsData = options.propsData
  }

  afterRender() {
    if (this.vueComponent) {
      this.$el.find('#site-content-area').replaceWith(this.vueComponent.$el)
    }
    else{
      this.vueComponent = new this.VueComponent({
        el: this.$el.find('#site-content-area')[0],
        propsData: this.propsData,
        store: store
      })
      window.rootComponent = this.vueComponent
    }
    super.afterRender()
  }

  destroy() {
    if (store.state.page)
      store.unregisterModule('page')
    this.vueComponent.$destroy()
    this.vueComponent.$store = silentStore
  }
}