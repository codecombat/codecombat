# Template for classes with common functions, like hooking into the Mediator.
utils = require './../core/utils'
classCount = 0
makeScopeName = -> "class-scope-#{classCount++}"
doNothing = ->

module.exports = class CocoClass
  @nicks: []
  @nicksUsed: {}
  @remainingNicks: []
  @nextNick: ->
    return (@name or 'CocoClass') + ' ' + classCount unless @nicks.length
    @remainingNicks = if @remainingNicks.length then @remainingNicks else @nicks.slice()
    baseNick = @remainingNicks.splice(Math.floor(Math.random() * @remainingNicks.length), 1)[0]
    i = 0
    while true
      nick = if i then "#{baseNick} #{i}" else baseNick
      break unless @nicksUsed[nick]
      i++
    @nicksUsed[nick] = true
    nick

  subscriptions: {}
  shortcuts: {}

  # setup/teardown

  constructor: ->
    @nick = @constructor.nextNick()
    @subscriptions = utils.combineAncestralObject(@, 'subscriptions')
    @shortcuts = utils.combineAncestralObject(@, 'shortcuts')
    @listenToSubscriptions()
    @scope = makeScopeName()
    @listenToShortcuts()
    _.extend(@, Backbone.Events) if Backbone?

  destroy: ->
    # teardown subscriptions, prevent new ones
    @stopListening?()
    @off?()
    @unsubscribeAll()
    @stopListeningToShortcuts()
    @constructor.nicksUsed[@nick] = false
    @[key] = undefined for key of @
    @destroyed = true
    @off = doNothing
    @destroy = doNothing

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
    return unless Backbone?.Mediator?
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

  playSound: (trigger, volume=1) ->
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: trigger, volume: volume

  wait: (event) -> new Promise((resolve) => @once(event, resolve))
