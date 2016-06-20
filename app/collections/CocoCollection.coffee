CocoModel = require 'models/CocoModel'

module.exports = class CocoCollection extends Backbone.Collection
  loaded: false
  model: null

  initialize: (models, options) ->
    options ?= {}
    @model ?= options.model
    if not @model
      console.error @constructor.name, 'does not have a model defined. This will not do!'
    super(models, options)
    @setProjection options.project
    if options.url then @url = options.url
    @once 'sync', =>
      @loaded = true
      model.loaded = true for model in @models
    if window.application?.testing
      @fakeRequests = []
      @on 'request', -> @fakeRequests.push jasmine.Ajax.requests.mostRecent()

  getURL: ->
    return if _.isString @url then @url else @url()

  fetch: (options) ->
    options ?= {}
    if @project
      options.data ?= {}
      options.data.project = @project.join(',')
    @jqxhr = super(options)
    @loading = true
    @jqxhr

  setProjection: (@project) ->

  stringify: -> return JSON.stringify(@toJSON())