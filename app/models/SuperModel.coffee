module.exports = class SuperModel extends Backbone.Model
  constructor: ->
    @num = 0
    @denom = 0
    @progress = 0
    @resources = {}
    @rid = 0

    @models = {}
    @collections = {}

  # Since the supermodel has undergone some changes into being a loader and a cache interface,
  # it's a bit wonky to use. The next couple functions are meant to cover the majority of
  # use cases across the site. If they are used, the view will automatically handle errors,
  # retries, progress, and filling the cache. Note that the resource it passes back will not
  # necessarily have the same model or collection that was passed in, if it was fetched from
  # the cache.

  loadModel: (model, name, fetchOptions, value=1) ->
    cachedModel = @getModelByURL(model.getURL())
    if cachedModel
      console.debug 'Model cache hit', cachedModel.getURL(), 'already loaded', cachedModel.loaded
      if cachedModel.loaded
        res = @addModelResource(cachedModel, name, fetchOptions, 0)
        res.markLoaded()
        return res
      else
        res = @addModelResource(cachedModel, name, fetchOptions, value)
        res.markLoading()
        return res

    else
      @registerModel(model)
      console.debug 'Registering model', model.getURL()
      return @addModelResource(model, name, fetchOptions, value).load()

  loadCollection: (collection, name, fetchOptions, value=1) ->
    url = collection.getURL()
    if cachedCollection = @collections[url]
      console.debug 'Collection cache hit', url, 'already loaded', cachedCollection.loaded
      if cachedCollection.loaded
        res = @addModelResource(cachedCollection, name, fetchOptions, 0)
        res.markLoaded()
        return res
      else
        res = @addModelResource(cachedCollection, name, fetchOptions, value)
        res.markLoading()
        return res

    else
      @addCollection collection
      @listenToOnce collection, 'sync', (c) ->
        console.debug 'Registering collection', url
        @registerCollection c
      return @addModelResource(collection, name, fetchOptions, value).load()

  # replace or overwrite
  shouldSaveBackups: (model) -> false

  # Caching logic

  getModel: (ModelClass_or_url, id) ->
    return @getModelByURL(ModelClass_or_url) if _.isString(ModelClass_or_url)
    m = new ModelClass_or_url(_id: id)
    return @getModelByURL(m.getURL())

  getModelByURL: (modelURL) ->
    modelURL = modelURL() if _.isFunction(modelURL)
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

  registerModel: (model) ->
    @models[model.getURL()] = model

  getCollection: (collection) ->
    return @collections[collection.getURL()] or collection

  addCollection: (collection) ->
    # TODO: remove, instead just use registerCollection?
    url = collection.getURL()
    if @collections[url]? and @collections[url] isnt collection
      return console.warn "Tried to add Collection '#{url}' to SuperModel when we already had it."
    @registerCollection(collection)

  registerCollection: (collection) ->
    @collections[collection.getURL()] = collection
    # consolidate models
    for model, i in collection.models
      cachedModel = @getModelByURL(model.getURL())
      if cachedModel
        collection.models[i] = cachedModel
      else
        @registerModel(model)
    collection

  # Tracking resources being loaded for this supermodel

  finished: ->
    return @progress is 1.0 or not @denom

  addModelResource: (modelOrCollection, name, fetchOptions, value=1) ->
    modelOrCollection.saveBackups = @shouldSaveBackups(modelOrCollection)
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
    @listenToOnce(resource, 'loaded', @onResourceLoaded)
    @listenTo(resource, 'failed', @onResourceFailed)
    @denom += value
    @updateProgress() if @denom

  onResourceLoaded: (r) ->
    @num += r.value
    _.defer @updateProgress

  onResourceFailed: (source) ->
    @trigger('failed', source)

  updateProgress: =>
    # Because this is _.defer'd, this might end up getting called after
    # a bunch of things load all at once.
    # So make sure we only emit events if @progress has changed.
    newProg = if @denom then @num / @denom else 1
    return if @progress is newProg
    @progress = newProg
    @trigger('update-progress', @progress)
    @trigger('loaded-all') if @finished()

  getProgress: -> return @progress

  getResource: (rid) ->
    return @resources[rid]



class Resource extends Backbone.Model
  constructor: (name, value=1) ->
    @name = name
    @value = value
    @rid = -1 # Used for checking state and reloading
    @isLoading = false
    @isLoaded = false
    @model = null
    @jqxhr = null

  markLoaded: ->
    return if @isLoaded
    @trigger('loaded', @)
    @isLoaded = true
    @isLoading = false

  markFailed: ->
    return if @isLoaded
    @trigger('failed', {resource: @})
    @isLoaded = @isLoading = false
    @isFailed = true

  markLoading: ->
    @isLoaded = @isFailed = false
    @isLoading = true

  load: -> @



class ModelResource extends Resource
  constructor: (modelOrCollection, name, fetchOptions, value)->
    super(name, value)
    @model = modelOrCollection
    @fetchOptions = fetchOptions

  load: ->
    @markLoading()
    @fetchModel()
    @

  fetchModel: ->
    @jqxhr = @model.fetch(@fetchOptions) unless @model.loading
    @listenToOnce @model, 'sync', -> @markLoaded()
    @listenToOnce @model, 'error', -> @markFailed()



class RequestResource extends Resource
  constructor: (name, jqxhrOptions, value) ->
    super(name, value)
    @jqxhrOptions = jqxhrOptions

  load: ->
    @markLoading()
    @jqxhr = $.ajax(@jqxhrOptions)
    # make sure any other success/fail callbacks happen before resource loaded callbacks
    @jqxhr.done => _.defer => @markLoaded()
    @jqxhr.fail => _.defer => @markFailed()
    @



class SomethingResource extends Resource
