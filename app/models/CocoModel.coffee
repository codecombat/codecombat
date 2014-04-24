storage = require 'lib/storage'
deltasLib = require 'lib/deltas'
auth = require 'lib/auth'

class CocoModel extends Backbone.Model
  idAttribute: "_id"
  loaded: false
  loading: false
  saveBackups: false
  @schema: null

  initialize: ->
    super()
    if not @constructor.className
      console.error("#{@} needs a className set.")
    @markToRevert()
    @addSchemaDefaults()
    @once 'sync', @onLoaded, @
    @saveBackup = _.debounce(@saveBackup, 500)

  type: ->
    @constructor.className

  clone: (withChanges=true) ->
    # Backbone does not support nested documents
    clone = super()
    clone.set($.extend(true, {}, if withChanges then @attributes else @_revertAttributes))
    clone

  onLoaded: ->
    @loaded = true
    @loading = false
    @markToRevert()
    @loadFromBackup()

  set: ->
    res = super(arguments...)
    @saveBackup() if @saveBackups and @loaded and @hasLocalChanges()
    res

  loadFromBackup: ->
    return unless @saveBackups
    existing = storage.load @id
    if existing
      @set(existing, {silent:true})
      CocoModel.backedUp[@id] = @

  saveBackup: ->
    storage.save(@id, @attributes)
    CocoModel.backedUp[@id] = @

  @backedUp = {}
  schema: -> return @constructor.schema

  validate: ->
    result = tv4.validateMultiple(@attributes, @constructor.schema? or {})
    if result.errors?.length
      console.log @, "got validate result with errors:", result
    return result.errors unless result.valid

  save: (attrs, options) ->
    @set 'editPath', document.location.pathname
    options ?= {}
    success = options.success
    options.success = (resp) =>
      @trigger "save:success", @
      success(@, resp) if success
      @markToRevert()
      @clearBackup()
    @trigger "save", @
    return super attrs, options

  fetch: ->
    res = super(arguments...)
    @loading = true
    res

  markToRevert: ->
    if @type() is 'ThangType'
      @_revertAttributes = _.clone @attributes  # No deep clones for these!
    else
      @_revertAttributes = $.extend(true, {}, @attributes)

  revert: ->
    @set(@_revertAttributes, {silent: true}) if @_revertAttributes
    @clearBackup()

  clearBackup: ->
    storage.remove @id

  hasLocalChanges: ->
    not _.isEqual @attributes, @_revertAttributes

  cloneNewMinorVersion: ->
    newData = $.extend(null, {}, @attributes)
    clone = new @constructor(newData)
    clone

  cloneNewMajorVersion: ->
    clone = @cloneNewMinorVersion()
    clone.unset('version')
    clone

  isPublished: ->
    for permission in @get('permissions') or []
      return true if permission.target is 'public' and permission.access is 'read'
    false

  publish: ->
    if @isPublished() then throw new Error("Can't publish what's already-published. Can't kill what's already dead.")
    @set "permissions", (@get("permissions") or []).concat({access: 'read', target: 'public'})

  addSchemaDefaults: ->
    return if @addedSchemaDefaults
    @addedSchemaDefaults = true
    for prop, defaultValue of @constructor.schema.default or {}
      continue if @get(prop)?
      #console.log "setting", prop, "to", defaultValue, "from attributes.default"
      @set prop, defaultValue
    for prop, sch of @constructor.schema.properties or {}
      continue if @get(prop)?
      continue if prop is 'emails' # hack, defaults are handled through User.coffee's email-specific methods.
      #console.log "setting", prop, "to", sch.default, "from sch.default" if sch.default?
      @set prop, sch.default if sch.default?
    if @loaded
      @markToRevert()
      @loadFromBackup()

  getReferencedModels: (data, schema, path='/', shouldLoadProjection=null) ->
    # returns unfetched model shells for every referenced doc in this model
    # OPTIMIZE so that when loading models, it doesn't cause the site to stutter
    data ?= @attributes
    schema ?= @schema()
    models = []

    # TODO: Better schema/json walking
    if $.isArray(data) and schema.items?
      for subData, i in data
        models = models.concat(@getReferencedModels(subData, schema.items, path+i+'/', shouldLoadProjection))

    if $.isPlainObject(data) and schema.properties?
      for key, subData of data
        continue unless schema.properties[key]
        models = models.concat(@getReferencedModels(subData, schema.properties[key], path+key+'/', shouldLoadProjection))

    model = CocoModel.getReferencedModel data, schema, shouldLoadProjection
    models.push model if model
    return models

  @getReferencedModel: (data, schema, shouldLoadProjection=null) ->
    return null unless schema.links?
    linkObject = _.find schema.links, rel: "db"
    return null unless linkObject
    return null if linkObject.href.match("thang.type") and not @isObjectID(data)  # Skip loading hardcoded Thang Types for now (TODO)

    # not fully extensible, but we can worry about that later
    link = linkObject.href
    link = link.replace('{(original)}', data.original)
    link = link.replace('{(majorVersion)}', '' + (data.majorVersion ? 0))
    link = link.replace('{($)}', data)
    @getOrMakeModelFromLink(link, shouldLoadProjection)

  @getOrMakeModelFromLink: (link, shouldLoadProjection=null) ->
    makeUrlFunc = (url) -> -> url
    modelUrl = link.split('/')[2]
    modelModule = _.string.classify(modelUrl)
    modulePath = "models/#{modelModule}"
    window.loadedModels ?= {}

    try
      Model = require modulePath
      window.loadedModels[modulePath] = Model
    catch e
      console.error 'could not load model from link path', link, 'using path', modulePath
      return

    model = new Model()
    if shouldLoadProjection? model
      sep = if link.search(/\?/) is -1 then "?" else "&"
      link += sep + "project=true"
    model.url = makeUrlFunc(link)
    return model

  @isObjectID: (s) ->
    s.length is 24 and s.match(/[a-f0-9]/gi)?.length is 24

  hasReadAccess: (actor) ->
    # actor is a User object

    actor ?= auth.me
    return true if actor.isAdmin()
    if @get('permissions')?
      for permission in @get('permissions')
        if permission.target is 'public' or actor.get('_id') is permission.target
          return true if permission.access in ['owner', 'read']

    return false

  hasWriteAccess: (actor) ->
    # actor is a User object

    actor ?= auth.me
    return true if actor.isAdmin()
    if @get('permissions')?
      for permission in @get('permissions')
        if permission.target is 'public' or actor.get('_id') is permission.target
          return true if permission.access in ['owner', 'write']

    return false

  getDelta: ->
    differ = deltasLib.makeJSONDiffer()
    differ.diff @_revertAttributes, @attributes

  applyDelta: (delta) ->
    newAttributes = $.extend(true, {}, @attributes)
    jsondiffpatch.patch newAttributes, delta
    @set newAttributes

  getExpandedDelta: ->
    delta = @getDelta()
    deltasLib.expandDelta(delta, @_revertAttributes, @schema())

  watch: (doWatch=true) ->
    $.ajax("#{@urlRoot}/#{@id}/watch", {type:'PUT', data:{on:doWatch}})
    @watching = -> doWatch

  watching: ->
    return me.id in (@get('watchers') or [])
    
  populateI18N: (data, schema, path='') ->
    # TODO: Better schema/json walking
    sum = 0
    data ?= $.extend true, {}, @attributes
    schema ?= @schema() or {}
    if schema.properties?.i18n and _.isPlainObject(data) and not data.i18n?
      data.i18n = {}
      sum += 1
      
    if _.isPlainObject data
      for key, value of data
        numChanged = 0
        numChanged = @populateI18N(value, childSchema, path+'/'+key) if childSchema = schema.properties?[key]
        if numChanged and not path # should only do this for the root object
          @set key, value
        sum += numChanged
          
    if schema.items and _.isArray data
      sum += @populateI18N(value, schema.items, path+'/'+index) for value, index in data
    
    sum

module.exports = CocoModel
