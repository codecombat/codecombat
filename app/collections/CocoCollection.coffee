CocoModel = require 'models/CocoModel'

module.exports = class CocoCollection extends Backbone.Collection
  loaded: false
  model: null

  initialize: ->
    if not @model
      console.error @constructor.name, 'does not have a model defined. This will not do!'
    super()
    @once 'sync', =>
      @loaded = true
      model.loaded = true for model in @models

  getURL: ->
    return if _.isString @url then @url else @url()

  fetch: ->
    @jqxhr = super(arguments...)
    @loading = true
    @jqxhr
