module.exports = class SuperModel extends Backbone.Model
  constructor: ->
    @num = 0
    @denom = 0
    @progress = 0
    @resources = {}
    @rid = 0
    @maxProgress = 1

    @models = {}
    @collections = {}

  # Since the supermodel has undergone some changes into being a loader and a cache interface,
  # it's a bit wonky to use. The next couple functions are meant to cover the majority of
  # use cases across the site. If they are used, the view will automatically handle errors,
  # retries, progress, and filling the cache. Note that the resource it passes back will not
  # necessarily have the same model or collection that was passed in, if it was fetched from
  # the cache.

  report: ->
    # Useful for debugging why a SuperModel never finishes loading.
    console.info 'SuperModel report ------------------------'
    console.info "#{_.values(@resources).length} resources."
    unfinished = []
    for resource in _.values(@resources) when resource
      console.info "\t", resource.name, 'loaded', resource.isLoaded, resource.model
      unfinished.push resource unless resource.isLoaded
    unfinished
    
  numDuplicates: ->
    # For debugging. TODO: Prevent duplicates from happening!
    ids = (m.get('_id') for m in _.values(@models))
    return _.size(ids) - _.size(_.unique(ids))

  loadModel: (model, name, fetchOptions, value=1) ->
    # Deprecating name. Handle if name is not included
    value = fetchOptions if _.isNumber(fetchOptions)
    fetchOptions = name if _.isObject(name)
      
    # hero-ladder levels need remote opponent_session for latest session data (e.g. code)
    # Can't apply to everything since other features rely on cached models being more recent (E.g. level_session)
    # E.g.#2 heroConfig isn't necessarily saved to db in world map inventory modal, so we need to load the cached session on level start
    cachedModel = @getModelByURL(model.getURL()) unless fetchOptions?.cache is false and name is 'opponent_session'
    if cachedModel
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
      res = @addModelResource(model, name, fetchOptions, value)
      if model.loaded then res.markLoaded() else res.load()
      return res

  loadCollection: (collection, name, fetchOptions, value=1) ->
    # Deprecating name. Handle if name is not included
    value = fetchOptions if _.isNumber(fetchOptions)
    fetchOptions = name if _.isObject(name)
    
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
      onCollectionSynced = (c) ->
        if collection.url is c.url
          @registerCollection c
        else
          console.warn 'Sync triggered for collection', c
          console.warn 'Yet got other object', c
          @listenToOnce collection, 'sync', onCollectionSynced
      @listenToOnce collection, 'sync', onCollectionSynced
      res = @addModelResource(collection, name, fetchOptions, value)
      res.load() if not (res.isLoading or res.isLoaded)
      return res
      
  # Eventually should use only these functions. Use SuperModel just to track progress.
  trackModel: (model, value) ->
    res = @addModelResource(model, '', {}, value)
    res.listen()

  trackCollection: (collection, value) ->
    res = @addModelResource(collection, '', {}, value)
    res.listen()
  
  trackPromise: (promise, value=1) ->
    res = new Resource('', value)
    promise.then ->
      res.markLoaded()
    promise.catch (err) ->
      res.error = err
      res.markFailed()
    @storeResource(res, value)
    return promise
    
  trackRequest: (jqxhr, value=1) ->
    res = new Resource('', value)
    res.jqxhr = jqxhr
    jqxhr.done -> res.markLoaded()
    jqxhr.fail -> res.markFailed()
    @storeResource(res, value)
    return jqxhr
    
  trackRequests: (jqxhrs, value=1) -> @trackRequest(jqxhr, value) for jqxhr in jqxhrs

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

  getModelByOriginal: (ModelClass, original, filter=null) ->
    _.find @models, (m) ->
      m.get('original') is original and m.constructor.className is ModelClass.className and (not filter or filter(m))

  getModelByOriginalAndMajorVersion: (ModelClass, original, majorVersion=0) ->
    _.find @models, (m) ->
      return unless v = m.get('version')
      m.get('original') is original and v.major is majorVersion and m.constructor.className is ModelClass.className

  getModels: (ModelClass) ->
    # can't use instanceof. SuperModel gets passed between windows, and one window
    # will have different class objects than another window.
    # So compare className instead.
    if not ModelClass
      return _.values @models
    # Allow checking by string name to reduce module dependencies
    className = if _.isString(ModelClass) then ModelClass else ModelClass.className
    return (m for key, m of @models when m.constructor.className is className)

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
    @collections[collection.getURL()] = collection if collection.isCachable
    # consolidate models
    for model, i in collection.models
      cachedModel = @getModelByURL(model.getURL())
      if cachedModel
        clone = $.extend true, {}, model.attributes
        cachedModel.set(clone, {silent: true, fromMerge: true})
        #console.debug "Updated cached model <#{cachedModel.get('name') or cachedModel.getURL()}> with new data"
      else
        @registerModel(model)
    collection

  # Tracking resources being loaded for this supermodel

  finished: ->
    return (@progress is 1.0) or (not @denom) or @failed

  addModelResource: (modelOrCollection, name, fetchOptions, value=1) ->
    # Deprecating name. Handle if name is not included
    value = fetchOptions if _.isNumber(fetchOptions)
    fetchOptions = name if _.isObject(name)
    
    modelOrCollection.saveBackups = modelOrCollection.saveBackups or @shouldSaveBackups(modelOrCollection)
    @checkName(name)
    res = new ModelResource(modelOrCollection, name, fetchOptions, value)
    @storeResource(res, value)
    return res

  removeModelResource: (modelOrCollection) ->
    @removeResource _.find(@resources, (resource) -> resource?.model is modelOrCollection)

  addRequestResource: (name, jqxhrOptions, value=1) ->
    # Deprecating name. Handle if name is not included
    value = jqxhrOptions if _.isNumber(jqxhrOptions)
    jqxhrOptions = name if _.isObject(name)
    
    @checkName(name)
    res = new RequestResource(name, jqxhrOptions, value)
    @storeResource(res, value)
    return res

  addSomethingResource: (name, value=1) ->
    value = name if _.isNumber(name)
    @checkName(name)
    res = new SomethingResource(name, value)
    @storeResource(res, value)
    return res
    
  addPromiseResource: (promise, value=1) ->
    somethingResource = @addSomethingResource('some promise', value)
    promise.then(() -> somethingResource.markLoaded())
    promise.catch(() -> somethingResource.markFailed())

  checkName: (name) ->
    #if _.isString(name)
    #  console.warn("SuperModel name property deprecated. Remove '#{name}' from code.")

  storeResource: (resource, value) ->
    @rid++
    resource.rid = @rid
    @resources[@rid] = resource
    @listenToOnce(resource, 'loaded', @onResourceLoaded)
    @listenTo(resource, 'failed', @onResourceFailed)
    @denom += value
    _.defer @updateProgress if @denom

  removeResource: (resource) ->
    return unless @resources[resource.rid]
    @resources[resource.rid] = null
    --@num if resource.isLoaded
    --@denom
    _.defer @updateProgress

  onResourceLoaded: (r) ->
    return unless @resources[r.rid]
    @num += r.value
    _.defer @updateProgress
    r.clean()
    @stopListening r, 'failed', @onResourceFailed
    @trigger 'resource-loaded', r

  onResourceFailed: (r) ->
    return unless @resources[r.rid]
    @failed = true
    @trigger('failed', resource: r)
    r.clean()

  updateProgress: =>
    # Because this is _.defer'd, this might end up getting called after
    # a bunch of things load all at once.
    # So make sure we only emit events if @progress has changed.
    newProg = if @denom then @num / @denom else 1
    newProg = Math.min @maxProgress, newProg
    return if @progress >= newProg
    @progress = newProg
    @trigger('update-progress', @progress)
    @trigger('loaded-all') if @finished()

  setMaxProgress: (@maxProgress) ->
  resetProgress: -> @progress = 0
  clearMaxProgress: ->
    @maxProgress = 1
    _.defer @updateProgress

  getProgress: -> return @progress

  getResource: (rid) ->
    return @resources[rid]
    
  # Promises
  finishLoading: ->
    new Promise (resolve, reject) =>
      return resolve(@) if @finished()
      @once 'failed', ({resource}) ->
        jqxhr = resource.jqxhr
        reject({message: jqxhr?.responseJSON?.message or jqxhr?.responseText or resource.error or 'Unknown Error'})
      @once 'loaded-all', => resolve(@)

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
    @trigger('failed', @)
    @isLoaded = @isLoading = false
    @isFailed = true

  markLoading: ->
    @isLoaded = @isFailed = false
    @isLoading = true

  clean: ->
    # request objects get rather large. Clean them up after the request is finished.
    @jqxhr = null

  load: -> @

class ModelResource extends Resource
  constructor: (modelOrCollection, name, fetchOptions, value)->
    super(name, value)
    @model = modelOrCollection
    @fetchOptions = fetchOptions
    @jqxhr = @model.jqxhr
    @loadsAttempted = 0

  load: ->
    @markLoading()
    @fetchModel()
    @

#    # TODO: Track progress on requests and don't retry if progress was made recently.
#    # Probably use _.debounce and attach event listeners to xhr objects.
#
#    # This logic is for handling failed responses for level loading.
#    timeToWait = 5000
#    tryLoad = =>
#      return if this.isLoaded
#      if @loadsAttempted > 4
#        @markFailed()
#        return @
#      @markLoading()
#      @model.loading = false # So fetchModel can run again
#      if @loadsAttempted > 0
#        console.log "Didn't load model in #{timeToWait}ms (attempt ##{@loadsAttempted}), trying again: ", _.result(@model, 'url')
#      @fetchModel()
#      @listenTo @model, 'error', (levelComponent, request) ->
#        if request.status not in [408, 504, 522, 524]
#          clearTimeout(@timeoutID)
#      clearTimeout(@timeoutID) if @timeoutID
#      @timeoutID = setTimeout(tryLoad, timeToWait)
#      if application.testing
#        application.timeoutsToClear?.push(@timeoutID)
#      @loadsAttempted += 1
#      timeToWait *= 1.5
#    tryLoad()
#    @

  fetchModel: ->
    @jqxhr = @model.fetch(@fetchOptions) unless @model.loading
    @listen()

  listen: ->
    @listenToOnce @model, 'sync', -> @markLoaded()
    @listenToOnce @model, 'error', -> @markFailed()

  clean: ->
    @jqxhr = null
    @model.jqxhr = null

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
