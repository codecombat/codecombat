storage = require 'lib/storage'
deltasLib = require 'lib/deltas'
auth = require 'lib/auth'

class CocoSchema extends Backbone.Model
  constructor: (path, args...) ->
    super(args...)
    # @urlRoot = path + '/schema'
    @schemaName = path[4..].replace '.', '_'
    @schema = require 'schemas/' + @schemaName + '_schema'

# window.CocoSchema = CocoSchema.schema

class CocoModel extends Backbone.Model
  idAttribute: "_id"
  loaded: false
  loading: false
  saveBackups: false
  @schema: null

  initialize: ->
    super()
    @constructor.schema ?= @urlRoot[4..].replace '.', '_'
    if not @constructor.className
      console.error("#{@} needs a className set.")
    @markToRevert()
    if @constructor.schema?.loaded
      @addSchemaDefaults()
    else
      @loadSchema()
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
    if @constructor.schema?.loaded
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

  loadSchema: ->
    return if @constructor.schema.loading
    @constructor.schema = require 'schemas/' + @constructor.schema + '_schema' unless @constructor.schema.loaded
    @onConstructorSync()
    # @listenToOnce(@constructor.schema, 'sync', @onConstructorSync)

  onConstructorSync: ->
    @constructor.schema.loaded = true
    @addSchemaDefaults()
    @trigger 'schema-loaded'

  @hasSchema: -> return @schema?.loaded
  schema: -> return @constructor.schema

  validate: ->
    result = tv4.validateMultiple(@attributes, @constructor.schema? or {})
    if result.errors?.length
      console.log @, "got validate result with errors:", result
    return result.errors unless result.valid

  save: (attrs, options) ->
    options ?= {}
    success = options.success
    options.success = (resp) =>
      @trigger "save:success", @
      success(@, resp) if success
      @markToRevert()
      @clearBackup()
    @trigger "save", @
    patch.setStatus 'accepted' for patch in @acceptedPatches or []
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
    clone.acceptedPatches = @acceptedPatches
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
    return if @addedSchemaDefaults or not @constructor.hasSchema()
    @addedSchemaDefaults = true
    for prop, defaultValue of @constructor.schema.default or {}
      continue if @get(prop)?
      #console.log "setting", prop, "to", defaultValue, "from attributes.default"
      @set prop, defaultValue
    for prop, sch of @constructor.schema.properties or {}
      continue if @get(prop)?
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
    deltasLib.expandDelta(delta, @_revertAttributes, @schema().attributes)
    
  addPatchToAcceptOnSave: (patch) ->
    @acceptedPatches ?= []
    @acceptedPatches.push patch
    @acceptedPatches = _.uniq(@acceptedPatches, false, (p) -> p.id)

module.exports = CocoModel
