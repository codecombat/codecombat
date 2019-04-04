import VueComponentVue from './VueComponentView'

import store from 'core/store'
import cocoVueRouter from 'core/CocoVueRouter'

import Root from './Root'

export default class SingletonAppVueComponentView extends VueComponentVue {

  constructor () {
    // For now we only support the default the default base template
    super(null, {})
  }

  buildVueComponent () {
    this.router = cocoVueRouter()

    return new Vue({
      el: this.$el.find('#site-content-area')[0],

      store,
      router: this.router,

      render: (h) => h(Root)
    })
  }
}
