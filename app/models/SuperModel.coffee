module.exports = class SuperModel extends Backbone.Model
  constructor: ->
    @num = 0
    @denom = 0
    @progress = 0
    @resources = {}
    @rid = 0

    @models = {}
    @collections = {}
    
  # Caching logic

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

  registerModel: (model) ->
    url = model.url
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
        @registerModel(model)
    collection
    
  # New, loading tracking stuff

  finished: ->
    return @progress is 1.0 or Object.keys(@resources).length is 0

  addModelResource: (modelOrCollection, name, fetchOptions, value=1) ->
    @checkName(name)
    @registerModel(modelOrCollection)
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

  onResourceLoaded: (r) ->
    @num += r.value
    _.defer @updateProgress

  onResourceFailed: (source) ->
    @trigger('failed', source)

  updateProgress: =>
    # Because this is _.defer'd, this might end up getting called after 
    # a bunch of things load all at once.
    # So make sure we only emit events if @progress has changed.
    return if @progress is @num / @denom
    @progress = @num / @denom
    @trigger('update-progress', @progress)
    @trigger('loaded-all') if @finished()

  getProgress: -> return @progress



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
    
  markLoading: ->
    @isLoaded = false
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
    @jqxhr = $.ajax(jqxhrOptions)
    @jqxhr.done @markLoaded()
    @jqxhr.fail @markFailed()
    @



class SomethingResource extends Resource
