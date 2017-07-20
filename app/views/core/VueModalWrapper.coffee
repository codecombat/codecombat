ModalView = require 'views/core/ModalView'
store = require('core/store')

# Given a Vue modal class, generates a backbone-wrapped class
module.exports = (WrappedComponentClass) ->
  class VueModalWrapper extends ModalView
    # id: 'vue-modal-wrapper'
    template: require 'templates/core/vue-modal-wrapper'
    initialize: (@propsData) ->
      @listeners = []
    afterRender: ->
      super()
      target = @$el.find('#vue-modal-wrapper')
      if @component
        target.replaceWith(@component.$el)
      else
        @component = new WrappedComponentClass({
          el: target[0]
          store
          propsData: @propsData
        })
        for listener in @listeners
          @setupListener(listener)
    setupListener: (listener) ->
      @component.$on listener.eventName, () =>
        listener.callback(arguments...)
    on: (eventName, callback) ->
      super(arguments...) # fall back to Backbone events, eg 'hidden'
      # Allow `.on` to be called before component exists by queing up listeners
      @listeners.push({ eventName, callback })
      if @component
        @setupListener({ eventName, callback })
    destroy: ->
      @component.$destroy()
      super()
