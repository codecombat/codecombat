ModalView = require 'views/core/ModalView'
store = require('core/store')

module.exports = class VueModalWrapper extends ModalView
  # id: 'vue-modal-wrapper'
  template: require 'templates/core/vue-modal-wrapper'
  initialize: (@WrappedComponentClass, @propsData) ->
    @listeners = []
    @constructor.name = @WrappedComponentClass.name
  afterRender: ->
    target = @$el.find('#vue-modal-wrapper')
    if @component
      target.replaceWith(@component.$el)
    else
      console.log @propsData
      @component = new @WrappedComponentClass({
        el: target[0]
        store
        propsData: @propsData
      })
      for listener in @listeners
        @setupListener(listener)
  on: (eventName, callback) ->
    @listeners.push({ eventName, callback })
    if @component
      @setupListener({ eventName, callback })
  setupListener: (listener) ->
    @component.$on listener.eventName, () =>
      listener.callback(arguments...)
