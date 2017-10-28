CocoView = require 'views/core/CocoView'
ModalView = require 'views/core/ModalView'
RootView = require 'views/core/RootView'
store = require('core/store')

# Given a Vue modal/component class, generates a backbone-wrapped class
makeWrapperForClass = (ViewClass) ->
  return (WrappedComponentClass) ->
    class VueWrapper extends ViewClass
      id: switch ViewClass
        when RootView then WrappedComponentClass.options.name
        when ModalView then WrappedComponentClass.options.name
        when CocoView then null
      template: ->
        switch ViewClass
          when RootView then require('templates/base-flat')(this.getRenderData()) # TODO: generalize
          else '<div></div>'
      initialize: (@propsData) ->
        @listeners = []
      afterRender: ->
        super()
        # Modals get attached one layer higher than usual other views, and we don't want to clobber the .modal layer
        target = switch ViewClass
          when ModalView then @$el.find('div').first()
          when CocoView then @$el
          when RootView then @$el.find('#site-content-area')
        # debugger if ViewClass is ModalView
        if @vueComponent
          target.replaceWith(@vueComponent.$el)
        else
          # debugger
          # if WrappedComponentClass.storeModule
          #   unless _.isFunction(WrappedComponentClass.storeModule)
          #     throw new Error('@storeModule should be a function')
          #   store.registerModule('page', @WrappedComponentClass.storeModule())
          @vueComponent = new WrappedComponentClass({
            el: target[0]
            store
            @propsData
          })
          for listener in @listeners
            @setupListener(listener)
        if ViewClass is RootView
          window.rootComponent = @vueComponent
      setupListener: (listener) ->
        @vueComponent.$on listener.eventName, () =>
          listener.callback(arguments...)
      on: (eventName, callback) ->
        super(arguments...) # fall back to Backbone events, eg 'hidden'
        # Allow `.on` to be called before component exists by queing up listeners
        @listeners.push({ eventName, callback })
        if @vueComponent
          @setupListener({ eventName, callback })
      destroy: ->
        @vueComponent?.$destroy?()
        super()

module.exports = VueWrapper = {
  Modal: makeWrapperForClass(ModalView)
  Component: makeWrapperForClass(CocoView)
  RootComponent: makeWrapperForClass(RootView)
}
