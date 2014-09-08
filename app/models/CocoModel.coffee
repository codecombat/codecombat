storage = require 'lib/storage'
deltasLib = require 'lib/deltas'

class CocoModel extends Backbone.Model
  idAttribute: '_id'
  loaded: false
  loading: false
  saveBackups: false
  notyErrors: true
  @schema: null

  initialize: (attributes, options) ->
    super(arguments...)
    options ?= {}
    @setProjection options.project
    if not @constructor.className
      console.error("#{@} needs a className set.")
    @on 'sync', @onLoaded, @
    @on 'error', @onError, @
    @on 'add', @onLoaded, @
    @saveBackup = _.debounce(@saveBackup, 500)

  setProjection: (project) ->
    return if project is @project
    url = @getURL()
    url += '&project=' unless /project=/.test url
    url = url.replace '&', '?' unless /\?/.test url
    url = url.replace /project=[^&]*/, "project=#{project?.join(',') or ''}"
    url = url.replace /[&?]project=&/, '&' unless project?.length
    url = url.replace /[&?]project=$/, '' unless project?.length
    @setURL url
    @project = project

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

  attributesWithDefaults: undefined

  get: (attribute, withDefault=false) ->
    if withDefault
      if @attributesWithDefaults is undefined then @buildAttributesWithDefaults()
      return @attributesWithDefaults[attribute]
    else
      super(attribute)

  set: (attributes, options) ->
    delete @attributesWithDefaults
    inFlux = @loading or not @loaded
    @markToRevert() unless inFlux or @_revertAttributes or @project or options?.fromMerge
    res = super attributes, options
    @saveBackup() if @saveBackups and (not inFlux) and @hasLocalChanges()
    res

  buildAttributesWithDefaults: ->
    t0 = new Date()
    clone = $.extend true, {}, @attributes
    thisTV4 = tv4.freshApi()
    thisTV4.addSchema('#', @schema())
    thisTV4.addSchema('metaschema', require('schemas/metaschema'))
    TreemaNode.utils.populateDefaults(clone, @schema(), thisTV4)
    @attributesWithDefaults = clone
    console.debug "Populated defaults for #{@attributes.name or @type()} in #{new Date() - t0}ms"

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
    # Since Backbone unset only sets things to undefined instead of deleting them, we ignore undefined properties.
    definedAttributes = _.pick @attributes, (v) -> v isnt undefined
    errors = tv4.validateMultiple(definedAttributes, @constructor.schema or {}).errors
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
    options.headers['X-Current-Path'] = document.location?.pathname ? 'unknown'
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

  fetch: (options) ->
    options ?= {}
    options.data ?= {}
    options.data.project = @project.join(',') if @project
    @jqxhr = super(options)
    @loading = true
    @jqxhr

  markToRevert: ->
    if @type() is 'ThangType'
      # Don't deep clone the raw vector data, but do deep clone everything else.
      @_revertAttributes = _.clone @attributes
      for smallProp, value of @attributes when value and smallProp isnt 'raw'
        @_revertAttributes[smallProp] = _.cloneDeep value
    else
      @_revertAttributes = $.extend(true, {}, @attributes)

  revert: ->
    @clear({silent: true})
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
    for permission in (@get('permissions', true) ? [])
      return true if permission.target is 'public' and permission.access is 'read'
    false

  publish: ->
    if @isPublished() then throw new Error('Can\'t publish what\'s already-published. Can\'t kill what\'s already dead.')
    @set 'permissions', @get('permissions', true).concat({access: 'read', target: 'public'})

  @isObjectID: (s) ->
    s.length is 24 and s.match(/[a-f0-9]/gi)?.length is 24

  hasReadAccess: (actor) ->
    # actor is a User object
    actor ?= me
    return true if actor.isAdmin()
    for permission in (@get('permissions', true) ? [])
      if permission.target is 'public' or actor.get('_id') is permission.target
        return true if permission.access in ['owner', 'read']

    return false

  hasWriteAccess: (actor) ->
    # actor is a User object
    actor ?= me
    return true if actor.isAdmin()
    for permission in (@get('permissions', true) ? [])
      if permission.target is 'public' or actor.get('_id') is permission.target
        return true if permission.access in ['owner', 'write']

    return false

  getOwner: ->
    ownerPermission = _.find @get('permissions', true), access: 'owner'
    ownerPermission?.target

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
    for key, value of newAttributes
      delete newAttributes[key] if _.isEqual value, @attributes[key]

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
      data.i18n = {'-':'-'} # mongoose doesn't work with empty objects
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
    NewAchievementCollection = require '../collections/NewAchievementCollection' # Nasty mutual inclusion if put on top
    achievements = new NewAchievementCollection
    achievements.fetch
      success: (collection) ->
        me.fetch (success: -> Backbone.Mediator.publish('achievements:new', earnedAchievements: collection)) unless _.isEmpty(collection.models)
      error: ->
        console.error 'Miserably failed to fetch unnotified achievements', arguments

CocoModel.pollAchievements = _.debounce CocoModel.pollAchievements, 500

module.exports = CocoModel
