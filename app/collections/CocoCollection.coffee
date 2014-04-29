module.exports = class CocoCollection extends Backbone.Collection
  loaded: false

  initialize: ->
    super()
    @once 'sync', =>
      @loaded = true
      model.loaded = true for model in @models

  getURL: ->
    return if _.isString @url then @url else @url()