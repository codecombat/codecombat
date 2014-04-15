module.exports = class SuperModel extends Backbone.Model
  constructor: ->
    @num = 0
    @denom = 0
    @showing = false
    @progress = 0
    @resources = {}
    @rid = 0

    @models = {}
    @collections = {}
    @schemas = {}

  populateModel: (model, resName) ->
    @mustPopulate = model
    model.saveBackups = @shouldSaveBackups(model)

    url = model.url()
    @models[url] = model unless @models[url]?
    @modelLoaded(model) if model.loaded

    resName = url unless resName
    modelRes = @addModelResource(model, url)

    schema = model.schema()
    @schemas[schema.urlRoot] = schema

    modelRes.load()
    return modelRes

  # replace or overwrite
  shouldLoadReference: (model) -> true
  shouldLoadProjection: (model) -> false
  shouldPopulate: (url) -> true
  shouldSaveBackups: (model) -> false

  modelErrored: (model) ->
    @trigger 'error'
    @removeEventsFromModel(model)

  modelLoaded: (model) ->    
    @trigger 'loaded-one', model: model
    @removeEventsFromModel(model)

  removeEventsFromModel: (model) ->
    # "Request" resource may have no off()
    # "Something" resource may have no model.
    model?.off? 'sync', @modelLoaded, @
    model?.off? 'error', @modelErrored, @

  getModel: (ModelClass_or_url, id) ->
    return @getModelByURL(ModelClass_or_url) if _.isString(ModelClass_or_url)
    m = new ModelClass_or_url(_id: id)
    return @getModelByURL(m.url())

  getModelByURL: (modelURL) ->
    return @models[modelURL] or null

  getModelByOriginalAndMajorVersion: (ModelClass, original, majorVersion=0) ->
    _.find @models, (m) ->
      m.get('original') is original and m.get('version').major is majorVersion and m.constructor.className is ModelClass.className

  getModels: (ModelClass) ->
    # can't use instanceof. SuperModel gets passed between windows, and one window
    # will have different class objects than another window.
    # So compare className instead.
    return (m for key, m of @models when m.constructor.className is ModelClass.className) if ModelClass
    return _.values @models

  addModel: (model) ->
    url = model.url()
    return console.warn "Tried to add Model '#{url}' to SuperModel, but it wasn't loaded." unless model.loaded
    #return console.warn "Tried to add Model '#{url}' to SuperModel when we already had it." if @models[url]?
    @models[url] = model

  getCollection: (collection) ->
    url = collection.url
    url = url() if _.isFunction(url)
    return @collections[url] or collection

  addCollection: (collection) ->
    url = collection.url
    url = url() if _.isFunction(url)
    if @collections[url]?
      return console.warn "Tried to add Collection '#{url}' to SuperModel when we already had it."
    @collections[url] = collection

    # consolidate models
    for model, i in collection.models
      cachedModel = @getModelByURL(model.url())
      if cachedModel
        collection.models[i] = cachedModel
      else
        @addModel(model)
    collection

  finished: ->
    return @progress is 1.0 or Object.keys(@resources).length is 0


  addModelResource: (modelOrCollection, name, fetchOptions, value=1) ->
    @checkName(name)
    res = new ModelResource(modelOrCollection, name, fetchOptions, value)
    @storeResource(res, value)
    return res

  addRequestResource: (name, jqxhrOptions, value=1) ->
    @checkName(name)
    res = new RequestResource(name, jqxhrOptions, value)
    @storeResource(res, value)
    return res

  addSomethingResource: (name, value=1) ->
    @checkName(name)
    res = new SomethingResource(name, value)
    @storeResource(res, value)
    return res

  checkName: (name) ->
    if not name
      throw new Error('Resource name should not be empty.')

  storeResource: (resource, value) ->
    @rid++
    resource.rid = @rid
    @resources[@rid] = resource
    @listenToOnce(resource, 'resource:loaded', @onResourceLoaded)
    @listenToOnce(resource, 'resource:failed', @onResourceFailed)
    @denom += value

  loadResources: ->
    for rid, res of @resources
      res.load()

  onResourceLoaded: (r) ->
    @modelLoaded(r.model)
    # Check if the model has references
    if r.constructor.name is 'ModelResource'
      model = r.model
      @addModelRefencesToLoad(model)
      @updateProgress(r)
    else
      @updateProgress(r)

  onResourceFailed: (source) ->
    @trigger('resource:failed', source)
    @modelErrored(source.resource.model)

  addModelRefencesToLoad: (model) ->
    schema = model.schema?()
    return unless schema

    refs = model.getReferencedModels(model.attributes, schema.attributes, '/', @shouldLoadProjection)
    refs = [] unless @mustPopulate is model or @shouldPopulate(model)

    for ref, i in refs when @shouldLoadReference ref
      ref.saveBackups = @shouldSaveBackups(ref)
      refURL = ref.url()

      continue if @models[refURL]

      @models[refURL] = ref
      res = @addModelResource(ref, refURL)
      res.load()

  updateProgress: (r) =>     
    @num += r.value
    @progress = @num / @denom

    @trigger('superModel:updateProgress', @progress)
    @trigger('loaded-all') if @finished()

  getResource: (rid)->
    return @resources[rid]

  getProgress: -> return @progress

 
class Resource extends Backbone.Model
  constructor: (name, value=1) ->
    @name = name
    @value = value
    @dependencies = []
    @rid = -1 # Used for checking state and reloading
    @isLoading = false
    @isLoaded = false
    @model = null
    @loadDeferred = null
    @value = 1

  addDependency: (depRes) ->
    return if depRes.isLoaded
    @dependencies.push(depRes)

  markLoaded: ->
    @trigger('resource:loaded', @) if not @isLoaded
    @isLoaded = true
    @isLoading = false

  markFailed: (error) ->
    @trigger('resource:failed', {resource: @, error: error}) if not @isLoaded
    @isLoaded = false
    @isLoading = false

  load: ->
  isReadyForLoad: -> return not (@isloaded and @isLoading)
  getModel: -> @model

class ModelResource extends Resource
  constructor: (modelOrCollection, name, fetchOptions, value)->
    super(name, value)
    @model = modelOrCollection
    @fetchOptions = fetchOptions

  load: ->
    return @loadDeferred.promise() if @isLoading or @isLoaded

    @isLoading = true
    @loadDeferred = $.Deferred()
    $.when.apply($, @loadDependencies())
      .then(@onLoadDependenciesSuccess, @onLoadDependenciesFailed)
      .always(()=> @isLoading = false)

    return @loadDeferred.promise()

  loadDependencies: ->
    promises = []

    for dep in @dependencies
      continue if not dep.isReadyForLoad()
      promises.push(dep.load())

    return promises

  onLoadDependenciesSuccess: =>
    @model.fetch(@fetchOptions)

    @listenToOnce(@model, 'sync', ->
      @markLoaded()
      @loadDeferred.resolve(@)
    )

    @listenToOnce(@model, 'error', ->
      @markFailed('Failed to load resource.')
      @loadDeferred.reject(@)
    )

  onLoadDependenciesFailed: =>
    @markFailed('Failed to load dependencies.')
    @loadDeferred.reject(@)


class RequestResource extends Resource
  constructor: (name, jqxhrOptions, value) ->
    super(name, value)
    @model = $.ajax(jqxhrOptions)
    @jqxhrOptions = jqxhrOptions
    @loadDeferred = @model

  load: ->
    return @loadDeferred.promise() if @isLoading or @isLoaded

    @isLoading = true
    $.when.apply($, @loadDependencies())
      .then(@onLoadDependenciesSuccess, @onLoadDependenciesFailed)
      .always(()=> @isLoading = false)

    return @loadDeferred.promise()

  loadDependencies: ->
    promises = []

    for dep in @dependencies
      continue if not dep.isReadyForLoad()
      promises.push(dep.load())

    return promises

  onLoadDependenciesSuccess: =>
    @model = $.ajax(@jqxhrOptions)
    @model.done(
      => @markLoaded()
    ).fail(
      (jqXHR, textStatus, errorThrown) => 
        @markFailed(errorThrown)
    )

  onLoadDependenciesFailed: =>
    @markFailed('Failed to load dependencies.')


class SomethingResource extends Resource
  constructor: (name, value) ->
    super(value)
    @name = name
    @loadDeferred = $.Deferred()

  load: ->
    return @loadDeferred.promise()

  markLoaded: ->
    @loadDeferred.resolve()
    super()

  markFailed: (error) ->
    @loadDeferred.reject()
    super(error)
