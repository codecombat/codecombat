storage = require 'core/storage'
deltasLib = require 'core/deltas'

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
    # IE9 doesn't expose console object unless debugger tools are loaded
    unless console?
      window.console =
        info: ->
        log: ->
        error: ->
        debug: ->
    console.debug = console.log unless console.debug # Needed for IE10 and earlier

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

  onError: (level, jqxhr) ->
    @loading = false
    @jqxhr = null
    if jqxhr.status is 402
      Backbone.Mediator.publish 'level:subscription-required', {}

  onLoaded: ->
    @loaded = true
    @loading = false
    @jqxhr = null
    @loadFromBackup()

  getCreationDate: -> new Date(parseInt(@id.slice(0,8), 16)*1000)

  getNormalizedURL: -> "#{@urlRoot}/#{@id}"

  attributesWithDefaults: undefined

  get: (attribute, withDefault=false) ->
    if withDefault
      if @attributesWithDefaults is undefined then @buildAttributesWithDefaults()
      return @attributesWithDefaults[attribute]
    else
      super(attribute)

  set: (attributes, options) ->
    delete @attributesWithDefaults unless attributes is 'thangs'  # unless attributes is 'thangs': performance optimization for Levels keeping their cache.
    inFlux = @loading or not @loaded
    @markToRevert() unless inFlux or @_revertAttributes or @project or options?.fromMerge
    res = super attributes, options
    @saveBackup() if @saveBackups and (not inFlux)
    res

  buildAttributesWithDefaults: ->
    t0 = new Date()
    clone = $.extend true, {}, @attributes
    thisTV4 = tv4.freshApi()
    thisTV4.addSchema('#', @schema())
    thisTV4.addSchema('metaschema', require('schemas/metaschema'))
    TreemaUtils.populateDefaults(clone, @schema(), thisTV4)
    @attributesWithDefaults = clone
    duration = new Date() - t0
    console.debug "Populated defaults for #{@type()}#{if @attributes.name then ' ' + @attributes.name else ''} in #{duration}ms" if duration > 10

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
      console.trace?()
      return errors

  save: (attrs, options) ->
    options ?= {}
    originalOptions = _.cloneDeep(options)
    options.headers ?= {}
    options.headers['X-Current-Path'] = document.location?.pathname ? 'unknown'
    success = options.success
    error = options.error
    options.success = (model, res) =>
      @retries = 0
      @trigger 'save:success', @
      success(@, res) if success
      @markToRevert() if @_revertAttributes
      @clearBackup()
      CocoModel.pollAchievements()
      options.success = options.error = null  # So the callbacks can be garbage-collected.
    options.error = (model, res) =>
      if res.status is 0
        @retries ?= 0
        @retries += 1
        if @retries > 20
          msg = 'Your computer or our servers appear to be offline. Please try refreshing.'
          noty text: msg, layout: 'center', type: 'error', killer: true
          return
        else
          msg = $.i18n.t 'loading_error.connection_failure', defaultValue: 'Connection failed.'
          noty text: msg, layout: 'center', type: 'error', killer: true, timeout: 3000
          return _.delay((f = => @save(attrs, originalOptions)), 3000)
      error(@, res) if error
      return unless @notyErrors
      errorMessage = "Error saving #{@get('name') ? @type()}"
      console.log 'going to log an error message'
      console.warn errorMessage, res.responseJSON
      unless webkit?.messageHandlers  # Don't show these notys on iPad
        try
          noty text: "#{errorMessage}: #{res.status} #{res.statusText}", layout: 'topCenter', type: 'error', killer: false, timeout: 10000
        catch notyError
          console.warn "Couldn't even show noty error for", error, "because", notyError
      options.success = options.error = null  # So the callbacks can be garbage-collected.
    @trigger 'save', @
    return super attrs, options

  patch: (options) ->
    return false unless @_revertAttributes
    options ?= {}
    options.patch = true
    options.type = 'PUT'

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
    differ.diff(_.omit(@_revertAttributes, deltasLib.DOC_SKIP_PATHS), _.omit(@attributes, deltasLib.DOC_SKIP_PATHS))

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
    addedI18N = false
    if schema.properties?.i18n and _.isPlainObject(data) and not data.i18n?
      data.i18n = {'-':{'-':'-'}} # mongoose doesn't work with empty objects
      sum += 1
      addedI18N = true

    if _.isPlainObject data
      for key, value of data
        numChanged = 0
        numChanged = @populateI18N(value, childSchema, path+'/'+key) if childSchema = schema.properties?[key]
        if numChanged and not path # should only do this for the root object
          @set key, value
        sum += numChanged

    if schema.items and _.isArray data
      sum += @populateI18N(value, schema.items, path+'/'+index) for value, index in data

    @set('i18n', data.i18n) if addedI18N and not path # need special case for root i18n
    @updateI18NCoverage()
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

    CocoCollection = require 'collections/CocoCollection'
    Achievement = require 'models/Achievement'

    class NewAchievementCollection extends CocoCollection
      model: Achievement
      initialize: (me = require('core/auth').me) ->
        @url = "/db/user/#{me.id}/achievements?notified=false"

    achievements = new NewAchievementCollection
    achievements.fetch
      success: (collection) ->
        me.fetch (success: -> Backbone.Mediator.publish('achievements:new', earnedAchievements: collection)) unless _.isEmpty(collection.models)
      error: ->
        console.error 'Miserably failed to fetch unnotified achievements', arguments

  CocoModel.pollAchievements = _.debounce CocoModel.pollAchievements, 500


  #- Internationalization

  updateI18NCoverage: ->
    i18nObjects = @findI18NObjects()
    return unless i18nObjects.length
    langCodeArrays = (_.keys(i18n) for i18n in i18nObjects)
    @set('i18nCoverage', _.intersection(langCodeArrays...))

  findI18NObjects: (data, results) ->
    data ?= @attributes
    results ?= []

    if _.isPlainObject(data) or _.isArray(data)
      for [key, value] in _.pairs data
        if key is 'i18n'
          results.push value
        else if _.isPlainObject(value) or _.isArray(value)
          @findI18NObjects(value, results)

    return results

module.exports = CocoModel
