ModalView = require('./ModalView')
store = require('core/store')
silentStore = { commit: _.noop, dispatch: _.noop }

module.exports = class ModalComponent extends ModalView
  VueComponent: null # set this - will overwrite backbone modal
  vuexModule: null
  propsData: null

  afterRender: ->
    if @vueComponent
      @$el.find('#modal-base-flat').replaceWith(@vueComponent.$el)
    else
      if @vuexModule
        unless _.isFunction(@vuexModule)
          throw new Error('@vuexModule should be a function')
        store.registerModule('modal', @vuexModule())
      
      @vueComponent = new @VueComponent({
        el: @$el.find('#modal-base-flat')[0]
        propsData: @propsData
        store
      })
      super(arguments...)

  destroy: ->
    if @vuexModule
      store.unregisterModule('modal')
    # Reference for how to safely destroy a vue component:
    # https://forum.vuejs.org/t/add-component-to-dom-programatically/7308/12
    @vueComponent.$destroy()
    @vueComponent.$el.remove()
    @vueComponent.$store = silentStore
    @vueComponent = null
