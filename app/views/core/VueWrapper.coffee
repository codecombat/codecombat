CocoView = require 'views/core/CocoView'
ModalView = require 'views/core/ModalView'
store = require('core/store')

# Given a Vue modal class, generates a backbone-wrapped class
makeWrapperForClass = (ParentClass) ->
  return (WrappedComponentClass) ->
    class VueWrapper extends ParentClass
      # id: 'vue-modal-wrapper'
      template: require 'templates/core/vue-component-wrapper'
      initialize: (@propsData) ->
        @id = WrappedComponentClass.id ? null
        @listeners = []
      afterRender: ->
        super()
        target = @$el.find('.vue-component-wrapper')
        if @vueComponent
          target.replaceWith(@vueComponent.$el)
        else
          # TODO: Figure out why it's inserting an extra blank div in the DOM above the actual component's div
          # TODO: Figure out how to prevent doubling up of container elements (for insertSubView) and component root elements (for Vue itself)
          @vueComponent = new WrappedComponentClass({
            el: target[0]
            store
            @propsData
          })
          for listener in @listeners
            @setupListener(listener)
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
}
