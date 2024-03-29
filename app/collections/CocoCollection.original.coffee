CocoModel = require 'models/CocoModel'
globalVar = require 'core/globalVar'
utils = require 'core/utils'

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
    if globalVar.application?.testing
      @fakeRequests = []
      @on 'request', -> @fakeRequests.push jasmine.Ajax.requests.mostRecent()
    if options.saveBackups
      @on 'sync', ->
        for model in @models
          model.saveBackups = true
          model.loadFromBackup()

  getURL: ->
    return if _.isString @url then @url else @url()

  fetch: (options) ->
    options ?= {}
    if @project
      options.data ?= {}
      options.data.project = @project.join(',')
    if options.callOz
      url = options.url || @getURL()
      options.url = utils.getProductUrl('OZ', url)
    @jqxhr = super(options)
    @loading = true
    @jqxhr

  setProjection: (@project) ->

  stringify: -> return JSON.stringify(@toJSON())

  wait: (event) -> new Promise((resolve) => @once(event, resolve))
