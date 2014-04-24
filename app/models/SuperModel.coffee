class SuperModel
  constructor: ->
    @models = {}
    @collections = {}
    _.extend(@, Backbone.Events)

  populateModel: (model) ->
    @mustPopulate = model
    model.saveBackups = @shouldSaveBackups(model)
    model.fetch() unless model.loaded or model.loading
    @listenToOnce(model, 'sync', @modelLoaded) unless model.loaded
    @listenToOnce(model, 'error', @modelErrored) unless model.loaded
    url = model.url()
    @models[url] = model unless @models[url]?
    @modelLoaded(model) if model.loaded

  # replace or overwrite
  shouldLoadReference: (model) -> true
  shouldLoadProjection: (model) -> false
  shouldPopulate: (url) -> true
  shouldSaveBackups: (model) -> false

  modelErrored: (model) ->
    @trigger 'error'
    @removeEventsFromModel(model)

  modelLoaded: (model) ->
    schema = model.schema()
    refs = model.getReferencedModels(model.attributes, schema, '/', @shouldLoadProjection)
    refs = [] unless @mustPopulate is model or @shouldPopulate(model)
#    console.log 'Loaded', model.get('name')
    for ref, i in refs when @shouldLoadReference ref
      ref.saveBackups = @shouldSaveBackups(ref)
      refURL = ref.url()
      continue if @models[refURL]
      @models[refURL] = ref
      ref.fetch()
      @listenToOnce(ref, 'sync', @modelLoaded)

    @trigger 'loaded-one', model: model
    @trigger 'loaded-all' if @finished()
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

  progress: ->
    total = 0
    loaded = 0

    for model in _.values @models
      total += 1
      loaded += 1 if model.loaded

    return 1.0 unless total
    return loaded / total

  finished: ->
    return @progress() == 1.0

module.exports = SuperModel
