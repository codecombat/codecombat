RootView = require('./RootView')
store = require('core/store')
silentStore = { commit: _.noop, dispatch: _.noop }

module.exports = class RootComponent extends RootView
  VueComponent: null # set this
  vuexModule: null
  propsData: null

  afterRender: ->
    if @vueComponent
      @$el.find('#site-content-area').replaceWith(@vueComponent.$el)
    else
      if @vuexModule
        unless _.isFunction(@vuexModule)
          throw new Error('@vuexModule should be a function')
        store.registerModule('page', @vuexModule())

      @vueComponent = new @VueComponent({
        el: @$el.find('#site-content-area')[0]
        propsData: @propsData
        store
      })

      window.rootComponent = @vueComponent # Don't use this in code! Just for ease of development

    super(arguments...)

  destroy: ->
    if @vuexModule
      store.unregisterModule('page')
    @vueComponent.$destroy()
    @vueComponent.$store = silentStore
    # ignore all further changes to the store, since the module has been unregistered.
    # may later want to just ignore mutations and actions to the page module.
