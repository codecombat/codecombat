# Template for classes with common functions, like hooking into the Mediator.
utils = require './utils'
classCount = 0
makeScopeName = -> "class-scope-#{classCount++}"

module.exports = class CocoClass
  subscriptions: {}
  shortcuts: {}

  # setup/teardown

  constructor: ->
    @subscriptions = utils.combineAncestralObject(@, 'subscriptions')
    @shortcuts = utils.combineAncestralObject(@, 'shortcuts')
    @listenToSubscriptions()
    @scope = makeScopeName()
    @listenToShortcuts()
    _.extend(@, Backbone.Events) if Backbone?

  destroy: ->
    # teardown subscriptions, prevent new ones
    @stopListening?()
    @unsubscribeAll()
    @stopListeningToShortcuts()
    @[key] = undefined for key of @
    @destroyed = true
    @destroy = ->

  # subscriptions

  listenToSubscriptions: ->
    # for initting subscriptions
    return unless Backbone?.Mediator?
    for channel, func of @subscriptions
      func = utils.normalizeFunc(func, @)
      Backbone.Mediator.subscribe(channel, func, @)

  addNewSubscription: (channel, func) ->
    # this is for adding subscriptions on the fly, rather than at init
    return unless Backbone?.Mediator?
    return if @destroyed
    return unless @subscriptions[channel] is undefined
    func = utils.normalizeFunc(func, @)
    @subscriptions[channel] = func
    Backbone.Mediator.subscribe(channel, func, @)

  unsubscribeAll: ->
    for channel, func of @subscriptions
      func = utils.normalizeFunc(func, @)
      Backbone.Mediator.unsubscribe(channel, func, @)

  # keymaster shortcuts

  listenToShortcuts: ->
    return unless key?
    for shortcut, func of @shortcuts
      func = utils.normalizeFunc(func, @)
      key(shortcut, @scope, _.bind(func, @))

  stopListeningToShortcuts: ->
    return unless key?
    key.deleteScope(@scope)
