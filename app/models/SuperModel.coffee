module.exports = class SuperModel extends Backbone.Model
  constructor: ->
    @models = {}
    @collections = {}
    @schemas = {}
    @num = 0
    @denom = 0
    @showing = false
    @progress = 0

  populateModel: (model) ->
    console.debug 'gintau', 'SuperModel-populateModel', model

    @mustPopulate = model
    model.saveBackups = @shouldSaveBackups(model)
    # model.fetch() unless model.loaded or model.loading
    @listenToOnce(model, 'sync', @modelLoaded) unless model.loaded
    @listenToOnce(model, 'error', @modelErrored) unless model.loaded
    url = model.url()
    @models[url] = model unless @models[url]?
    @modelLoaded(model) if model.loaded

    modelRes = @addModelResource(model, url)
    schema = model.schema()
    schemaRes = @addModelResource(schema, schema.urlRoot)
    @schemas[schema.urlRoot] = schema
    modelRes.addDependency(schemaRes.name)

    modelRes.load()

  # replace or overwrite
  shouldLoadReference: (model) -> true
  shouldLoadProjection: (model) -> false
  shouldPopulate: (url) -> true
  shouldSaveBackups: (model) -> false

  modelErrored: (model) ->
    @trigger 'error'
    @removeEventsFromModel(model)

  modelLoaded: (model) ->
    ###

    model.loadSchema()
    schema = model.schema()

    # Load schema first.
    unless schema.loaded
      @schemas[schema.urlRoot] = schema
      return schema.once('sync', => @modelLoaded(model))

    refs = model.getReferencedModels(model.attributes, schema.attributes, '/', @shouldLoadProjection)
    refs = [] unless @mustPopulate is model or @shouldPopulate(model)

    # console.debug 'gintau', 'superModel-refs', model, refs

    # load references.
    for ref, i in refs when @shouldLoadReference ref
      ref.saveBackups = @shouldSaveBackups(ref)
      refURL = ref.url()
      continue if @models[refURL]
      @models[refURL] = ref
      ref.fetch()
      @listenToOnce(ref, 'sync', @modelLoaded)

    ###

    @trigger 'loaded-one', model: model
    # @trigger 'loaded-all' if @finished()
    @removeEventsFromModel(model)

  removeEventsFromModel: (model) ->
    model.off 'sync', @modelLoaded, @
    model.off 'error', @modelErrored, @

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

    ###
  progress: ->
    total = 0
    loaded = 0

    for model in _.values @models
      total += 1
      loaded += 1 if model.loaded
    for schema in _.values @schemas
      total += 1
      loaded += 1 if schema.loaded

    return 1.0 unless total
    return loaded / total
###

  finished: ->
    console.debug 'gintau', 'trigger-loaded-all' if @progress == 1.0
    return @progress == 1.0



  addModelResource: (modelOrCollection, name, fetchOptions, value=1)->
    @checkName(name)
    res = new ModelResource(modelOrCollection, name, fetchOptions, value)
    @storeResource(name, res, value)
    return res

  addRequestResource: (name, jqxhrOptions, value=1)->
    @checkName(name)
    res = new RequestResource(name, jqxhrOptions, value)
    @storeResource(name, res, value)
    return res

  addSomethingResource: (name, value=1)->
    @checkName(name)
    res = new SomethingResource(name, value)
    @storeResource(name, res, value)
    return res

  checkName: (name)->
    if not name
      throw new Error('Resource name should not be empty.')
    if name in ResourceManager.resources
      throw new Error('Resource name has been used.')

  storeResource: (name, resource, value)->
    ResourceManager.resources[name] = resource
    @listenToOnce(resource, 'resource:loaded', @onResourceLoaded)
    @listenToOnce(resource, 'resource:failed', @onResourceFailed)
    @denom += value

  loadResources: ()->
    for name, res of ResourceManager.resources
      res.load()

  onResourceLoaded: (r)=> 
    # Check if the model has references
    console.debug 'gintau', 'updateProgress', r.constructor.name
    if r.constructor.name == 'ModelResource'
      model = r.model
      @addModelRefencesToLoad(model)
      @updateProgress(r)
    else
      console.debug 'gintau', 'updateProgressWithoutAddReferences'
      @updateProgress(r)

  onResourceFailed: (r)=>

  addModelRefencesToLoad: (model)->
    schema = model.schema?()
    return unless schema

    refs = model.getReferencedModels(model.attributes, schema.attributes, '/', @shouldLoadProjection)
    refs = [] unless @mustPopulate is model or @shouldPopulate(model)

    console.debug 'gintau', 'superModel-refs', model, refs
    for ref, i in refs when @shouldLoadReference ref
      ref.saveBackups = @shouldSaveBackups(ref)
      refURL = ref.url()

      continue if @models[refURL]

      @models[refURL] = ref
      res = @addModelResource(ref, refURL)
      res.load()

  updateProgress: (r)=>     
    @num += r.value
    @progress = @num / @denom

    console.debug 'gintau', 'updateProgress', @num, @denom, @progress
    @trigger('superModel:updateProgress', @progress)
    @trigger 'loaded-all' if @finished()

  getResource: (name)->
    return ResourceManager.resources[name]

# Both SuperModel and Resource access this class.
class ResourceManager
  @resources: {}

class Resource extends Backbone.Model
  constructor: (name, value=1)->
    @name = name
    @value = value
    @dependencies = []
    @isLoading = false
    @isLoaded = false
    @model = null
    @loadDeferred = null
    @value = 1

  addDependency: (name)->
    depRes = ResourceManager.resources[name]
    throw new Error('Resource not found') unless depRes
    return if (depRes.isLoaded or name == @name)
    @dependencies.push(name)

  markLoaded: ()->
    console.debug 'gintau', 'markLoaded', @model
    @trigger('resource:loaded', @) if not @isLoaded
    @isLoaded = true
    @isLoading = false

  markFailed: ()->
    console.debug 'gintau', 'markLoaded', @model  
    @trigger('resource:failed', @) if not @isLoaded
    @isLoaded = false
    @isLoading = false

  load: ()->
  isReadyForLoad: ()-> return not (@isloaded and @isLoading)
  getModel: ()-> @model

class ModelResource extends Resource
  constructor: (modelOrCollection, name, fetchOptions, value)->
    super(name, value)
    @model = modelOrCollection
    @fetchOptions = fetchOptions

  load: ()->
    return @loadDeferred.promise() if @isLoading or @isLoaded
    console.debug 'gintau', 'startLoading', @model

    @isLoading = true
    @loadDeferred = $.Deferred()
    $.when.apply($, @loadDependencies())
      .then(@onLoadDependenciesSuccess, @onLoadDependenciesFailed)
      .always(()=> @isLoading = false)

    return @loadDeferred.promise()

  loadDependencies: ()->
    promises = []
    console.debug 'gintau', 'loadDependencies-Dependencies', @name, @dependencies

    for resName in @dependencies
      dep = ResourceManager.resources[resName]
      console.debug 'gintau', 'loadDependencies-name', resName, @name
      continue if not dep.isReadyForLoad()
      promises.push(dep.load())

    console.debug 'gintau', 'loadDependencies-promises', promises, @name
    return promises

  onLoadDependenciesSuccess: ()=>
    console.debug 'gintau', 'onLoadDependenciesSuccess', 'startFetch', @model
    @model.fetch(@fetchOptions)

    @listenToOnce(@model, 'sync', ()=>
      @markLoaded()
      @loadDeferred.resolve(@)
    )

    @listenToOnce(@model, 'error', ()=>
      @markFailed()
      @loadDeferred.reject(@)
    )

  onLoadDependenciesFailed: ()=>
    console.debug 'gintau', 'onLoadDependenciesFailed', model
    @markFailed()
    @loadDeferred.reject(@)


class RequestResource extends Resource
  constructor: (name, jqxhrOptions, value)->
    super(name, value)
    @model = $.ajax(jqxhrOptions)
    @jqxhrOptions = jqxhrOptions
    @loadDeferred = @model

  load: ()->
    return @loadDeferred.promise() if @isLoading or @isLoaded

    @isLoading = true
    $.when.apply($, @loadDependencies())
      .then(@onLoadDependenciesSuccess, @onLoadDependenciesFailed)
      .always(()=> @isLoading = false)

    return @loadDeferred.promise()

  loadDependencies: ()->
    promises = []
    for depName in @dependecies
      dep = ResourceManager.resources[depName]
      continue if not dep.isReadyForLoad()
      promises.push(dep.load())

    return promises

  onLoadDependenciesSuccess: ()->
    @model = $.ajax(@jqxhrOptions)
    @model.done(()=> @markLoaded()).failed(()=> @markFailed())

  onLoadDependenciesFailed: ()->
    @markFailed()


class SomethingResource extends Resource
  constructor: (name, value)->
    super(value)
    @name = name
    @loadDeferred = $.Deferred()

  load: ()->
    return @loadDeferred.promise()

  markLoaded: ()->
    @loadDeferred.resolve()
    super()

  markFailed: ()->
    @loadDeferred.reject()
    super()