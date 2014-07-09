storage = require 'lib/storage'
deltasLib = require 'lib/deltas'

NewAchievementCollection = require '../collections/NewAchievementCollection'

class CocoModel extends Backbone.Model
  idAttribute: '_id'
  loaded: false
  loading: false
  saveBackups: false
  notyErrors: true
  @schema: null

  getMe: -> @me or @me = require('lib/auth').me

  initialize: ->
    super()
    if not @constructor.className
      console.error("#{@} needs a className set.")
    @addSchemaDefaults()
    @on 'sync', @onLoaded, @
    @on 'error', @onError, @
    @on 'add', @onLoaded, @
    @saveBackup = _.debounce(@saveBackup, 500)

  type: ->
    @constructor.className

  clone: (withChanges=true) ->
    # Backbone does not support nested documents
    clone = super()
    clone.set($.extend(true, {}, if withChanges then @attributes else @_revertAttributes))
    clone

  onError: ->
    @loading = false
    @jqxhr = null

  onLoaded: ->
    @loaded = true
    @loading = false
    @jqxhr = null
    @loadFromBackup()

  getNormalizedURL: -> "#{@urlRoot}/#{@id}"

  set: ->
    inFlux = @loading or not @loaded
    @markToRevert() unless inFlux or @_revertAttributes
    res = super(arguments...)
    @saveBackup() if @saveBackups and (not inFlux) and @hasLocalChanges()
    res

  loadFromBackup: ->
    return unless @saveBackups
    existing = storage.load @id
    if existing
      @set(existing, {silent: true})
      CocoModel.backedUp[@id] = @

  saveBackup: -> @saveBackupNow()
    
  saveBackupNow: ->
    storage.save(@id, @attributes)
    CocoModel.backedUp[@id] = @

  @backedUp = {}
  schema: -> return @constructor.schema

  getValidationErrors: ->
    errors = tv4.validateMultiple(@attributes, @constructor.schema or {}).errors
    return errors if errors?.length

  validate: ->
    errors = @getValidationErrors()
    if errors?.length
      console.debug "Validation failed for #{@constructor.className}: '#{@get('name') or @}'."
      for error in errors
        console.debug "\t", error.dataPath, ':', error.message
      return errors

  save: (attrs, options) ->
    options ?= {}
    options.headers ?= {}
    options.headers['X-Current-Path'] = document.location.pathname
    success = options.success
    error = options.error
    options.success = (model, res) =>
      @trigger 'save:success', @
      success(@, res) if success
      @markToRevert() if @_revertAttributes
      @clearBackup()
      CocoModel.pollAchievements()
    options.error = (model, res) =>
      error(@, res) if error
      return unless @notyErrors
      errorMessage = "Error saving #{@get('name') ? @type()}"
      console.error errorMessage, res.responseJSON
      noty text: "#{errorMessage}: #{res.status} #{res.statusText}", layout: 'topCenter', type: 'error', killer: false, timeout: 10000
    @trigger 'save', @
    return super attrs, options

  patch: (options) ->
    return false unless @_revertAttributes
    options ?= {}
    options.patch = true

    attrs = {_id: @id}
    keys = []
    for key in _.keys @attributes
      unless _.isEqual @attributes[key], @_revertAttributes[key]
        attrs[key] = @attributes[key]
        keys.push key

    return unless keys.length
    console.debug 'Patching', @get('name') or @, keys
    @save(attrs, options)

  fetch: ->
    @jqxhr = super(arguments...)
    @loading = true
    @jqxhr

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
    @_revertAttributes and not _.isEqual @attributes, @_revertAttributes

  cloneNewMinorVersion: ->
    newData = _.clone @attributes
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
    if @isPublished() then throw new Error('Can\'t publish what\'s already-published. Can\'t kill what\'s already dead.')
    @set 'permissions', (@get('permissions') or []).concat({access: 'read', target: 'public'})

  addSchemaDefaults: ->
    return if @addedSchemaDefaults
    @addedSchemaDefaults = true
    for prop, defaultValue of @constructor.schema.default or {}
      continue if @get(prop)?
      #console.log 'setting', prop, 'to', defaultValue, 'from attributes.default'
      @set prop, defaultValue
    for prop, sch of @constructor.schema.properties or {}
      continue if @get(prop)?
      continue if prop is 'emails' # hack, defaults are handled through User.coffee's email-specific methods.
      #console.log 'setting', prop, 'to', sch.default, 'from sch.default' if sch.default?
      @set prop, sch.default if sch.default?
    if @loaded
      @loadFromBackup()

  @isObjectID: (s) ->
    s.length is 24 and s.match(/[a-f0-9]/gi)?.length is 24

  hasReadAccess: (actor) ->
    # actor is a User object

    actor ?= @getMe()
    return true if actor.isAdmin()
    if @get('permissions')?
      for permission in @get('permissions')
        if permission.target is 'public' or actor.get('_id') is permission.target
          return true if permission.access in ['owner', 'read']

    return false

  hasWriteAccess: (actor) ->
    # actor is a User object

    actor ?= @getMe()
    return true if actor.isAdmin()
    if @get('permissions')?
      for permission in @get('permissions')
        if permission.target is 'public' or actor.get('_id') is permission.target
          return true if permission.access in ['owner', 'write']

    return false

  getDelta: ->
    differ = deltasLib.makeJSONDiffer()
    differ.diff @_revertAttributes, @attributes

  getDeltaWith: (otherModel) ->
    differ = deltasLib.makeJSONDiffer()
    differ.diff @attributes, otherModel.attributes

  applyDelta: (delta) ->
    newAttributes = $.extend(true, {}, @attributes)
    try
      jsondiffpatch.patch newAttributes, delta
    catch error
      console.error 'Error applying delta\n', JSON.stringify(delta, null, '\t'), '\n\nto attributes\n\n', newAttributes
      return false
    @set newAttributes
    return true

  getExpandedDelta: ->
    delta = @getDelta()
    deltasLib.expandDelta(delta, @_revertAttributes, @schema())

  getExpandedDeltaWith: (otherModel) ->
    delta = @getDeltaWith(otherModel)
    deltasLib.expandDelta(delta, @attributes, @schema())

  watch: (doWatch=true) ->
    $.ajax("#{@urlRoot}/#{@id}/watch", {type: 'PUT', data: {on: doWatch}})
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

  @getReferencedModel: (data, schema) ->
    return null unless schema.links?
    linkObject = _.find schema.links, rel: 'db'
    return null unless linkObject
    return null if linkObject.href.match('thang.type') and not @isObjectID(data)  # Skip loading hardcoded Thang Types for now (TODO)

    # not fully extensible, but we can worry about that later
    link = linkObject.href
    link = link.replace('{(original)}', data.original)
    link = link.replace('{(majorVersion)}', '' + (data.majorVersion ? 0))
    link = link.replace('{($)}', data)
    @getOrMakeModelFromLink(link)

  @getOrMakeModelFromLink: (link) ->
    makeUrlFunc = (url) -> -> url
    modelUrl = link.split('/')[2]
    modelModule = _.string.classify(modelUrl)
    modulePath = "models/#{modelModule}"

    try
      Model = require modulePath
    catch e
      console.error 'could not load model from link path', link, 'using path', modulePath
      return

    model = new Model()
    model.url = makeUrlFunc(link)
    return model

  setURL: (url) ->
    makeURLFunc = (u) -> -> u
    @url = makeURLFunc(url)
    @

  getURL: ->
    return if _.isString @url then @url else @url()

  @pollAchievements: ->
    achievements = new NewAchievementCollection
    achievements.fetch(
      success: (collection) ->
        me.fetch (success: -> Backbone.Mediator.publish('achievements:new', collection)) unless _.isEmpty(collection.models)
    )

CocoModel.pollAchievements = _.debounce CocoModel.pollAchievements, 500

module.exports = CocoModel
