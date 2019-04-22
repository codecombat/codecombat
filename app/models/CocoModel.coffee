storage = require 'core/storage'
locale = require 'locale/locale'
utils = require 'core/utils'

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
    @usesVersions = @schema()?.properties?.version?
    if window.application?.testing
      @fakeRequests = []
      @on 'request', -> @fakeRequests.push jasmine.Ajax.requests.mostRecent()

  created: -> new Date(parseInt(@id.substring(0, 8), 16) * 1000)

  backupKey: ->
    if @usesVersions then @id else @id  # + ':' + @attributes.__v  # TODO: doesn't work because __v doesn't actually increment. #2061
    # if fixed, RevertModal will also need the fix

  setProjection: (project) ->
    # TODO: ends up getting done twice, since the URL is modified and the @project is modified. So don't do this, just set project directly... (?)
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
    clone.set($.extend(true, {}, if withChanges or not @_revertAttributes then @attributes else @_revertAttributes))
    if @_revertAttributes and not withChanges
      # remove any keys that are in the current attributes not in the snapshot
      for key in _.difference(_.keys(clone.attributes), _.keys(@_revertAttributes))
        clone.unset(key)
    clone

  onError: (level, jqxhr) ->
    @loading = false
    @jqxhr = null
    if jqxhr.status is 402
      if _.contains(jqxhr.responseText, 'must be enrolled')
        Backbone.Mediator.publish 'level:license-required', {}
      else if _.contains(jqxhr.responseText, 'be in a course')
        Backbone.Mediator.publish 'level:course-membership-required', {}
      else
        Backbone.Mediator.publish 'level:subscription-required', {}

  onLoaded: ->
    @loaded = true
    @loading = false
    @jqxhr = null
    @loadFromBackup()

  getCreationDate: -> new Date(parseInt(@id.slice(0,8), 16)*1000)

  getNormalizedURL: -> "#{@urlRoot}/#{@id}"

  getTranslatedName: ->
    utils.i18n(@attributes, 'name')

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
    existing = storage.load @backupKey()
    if existing
      @set(existing, {silent: true})
      CocoModel.backedUp[@backupKey()] = @

  saveBackup: -> @saveBackupNow()

  saveBackupNow: ->
    storage.save(@backupKey(), @attributes)
    CocoModel.backedUp[@backupKey()] = @

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
      unless application?.testing
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
          try
            noty text: msg, layout: 'center', type: 'error', killer: true, timeout: 3000
          catch notyError
            console.warn "Couldn't even show noty error for", error, "because", notyError
          return _.delay((f = => @save(attrs, originalOptions)), 3000)
      error(@, res) if error
      return unless @notyErrors
      errorMessage = "Error saving #{@get('name') ? @type()}"
      console.log 'going to log an error message'
      console.warn errorMessage, res.responseJSON
      unless webkit?.messageHandlers  # Don't show these notys on iPad
        try
          noty text: "#{errorMessage}: #{res.status} #{res.statusText}\n#{res.responseText}", layout: 'topCenter', type: 'error', killer: false, timeout: 10000
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
    @save(attrs, options)

  fetch: (options) ->
    options ?= {}
    options.data ?= {}
    options.data.project = @project.join(',') if @project
    #console.error @constructor.className, @, "fetching with cache?", options.cache, "options", options  # Useful for debugging cached IE fetches
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
    storage.remove @backupKey()

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
    return true if actor.isArtisan() and @editableByArtisans
    for permission in (@get('permissions', true) ? [])
      if permission.target is 'public' or actor.get('_id') is permission.target
        return true if permission.access in ['owner', 'read']

    return false

  hasWriteAccess: (actor) ->
    # actor is a User object
    actor ?= me
    return true if actor.isAdmin()
    return true if actor.isArtisan() and @editableByArtisans
    for permission in (@get('permissions', true) ? [])
      if permission.target is 'public' or actor.get('_id') is permission.target
        return true if permission.access in ['owner', 'write']

    return false

  getOwner: ->
    ownerPermission = _.find @get('permissions', true), access: 'owner'
    ownerPermission?.target

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
    if schema.oneOf # get populating the Programmable component config to work
      schema = _.find(schema.oneOf, {type: 'object'}) or schema
    addedI18N = false
    if schema.properties?.i18n and _.isPlainObject(data) and not data.i18n?
      data.i18n = {'-':{'-':'-'}} # mongoose doesn't work with empty objects
      sum += 1
      addedI18N = true

    if _.isPlainObject data
      for key, value of data
        numChanged = 0
        childSchema = schema.properties?[key]
        if not childSchema and _.isObject(schema.additionalProperties)
          childSchema = schema.additionalProperties
        if childSchema
          numChanged = @populateI18N(value, childSchema, path+'/'+key)
        if numChanged and not path # should only do this for the root object
          @set key, value
        sum += numChanged

    if schema.items and _.isArray data
      sum += @populateI18N(value, schema.items, path+'/'+index) for value, index in data

    @set('i18n', data.i18n) if addedI18N and not path # need special case for root i18n
    @updateI18NCoverage() if not path  # only need to do this at the highest level
    sum

  setURL: (url) ->
    makeURLFunc = (u) -> -> u
    @url = makeURLFunc(url)
    @

  getURL: ->
    return if _.isString @url then @url else @url()

  @pollAchievements: ->
    return if application?.testing

    CocoCollection = require 'collections/CocoCollection'
    EarnedAchievement = require 'models/EarnedAchievement'

    class NewAchievementCollection extends CocoCollection
      model: EarnedAchievement
      initialize: (me = require('core/auth').me) ->
        @url = "/db/user/#{me.id}/achievements?notified=false"

    achievements = new NewAchievementCollection
    achievements.fetch
      success: (collection) ->
        me.fetch (cache: false, success: -> Backbone.Mediator.publish('achievements:new', earnedAchievements: collection)) unless _.isEmpty(collection.models)
      error: ->
        console.error 'Miserably failed to fetch unnotified achievements', arguments
      cache: false

  CocoModel.pollAchievements = _.debounce CocoModel.pollAchievements, 500


  #- Internationalization

  updateI18NCoverage: (attributes) ->
    langCodeArrays = []
    pathToData = {}
    attributes ?= @attributes

    # TODO: Share this code between server and client
    # NOTE: If you edit this, edit the server side version as well!
    TreemaUtils.walk(attributes, @schema(), null, (path, data, workingSchema) ->
      # Store parent data for the next block...
      if data?.i18n
        pathToData[path] = data

      if _.string.endsWith path, 'i18n'
        i18n = data

        # grab the parent data
        parentPath = path[0...-5]
        parentData = pathToData[parentPath]

        # use it to determine what properties actually need to be translated
        props = workingSchema.props or []
        props = (prop for prop in props when parentData[prop] and prop not in ['sound', 'soundTriggers'])
        return unless props.length
        return if 'additionalProperties' of i18n  # Workaround for #2630: Programmable is weird

        # get a list of lang codes where its object has keys for every prop to be translated
        coverage = _.filter(_.keys(i18n), (langCode) ->
          translations = i18n[langCode]
          translations and _.all((translations[prop] for prop in props))
        )
        #console.log 'got coverage', coverage, 'for', path, props, workingSchema, parentData
        langCodeArrays.push coverage
    )

    return unless langCodeArrays.length
    # language codes that are covered for every i18n object are fully covered
    overallCoverage = _.intersection(langCodeArrays...)
    @set('i18nCoverage', overallCoverage)

  deleteI18NCoverage: (options={}) ->
    options.url = @url() + '/i18n-coverage'
    options.type = 'DELETE'
    return $.ajax(options)

  saveNewMinorVersion: (attrs, options={}) ->
    options.url = @url() + '/new-version'
    options.type = 'POST'
    return @save(attrs, options)

  saveNewMajorVersion: (attrs, options={}) ->
    attrs = attrs or _.omit(@attributes, 'version')
    options.url = @url() + '/new-version'
    options.type = 'POST'
    options.patch = true # do not let version get sent along
    return @save(attrs, options)

  fetchPatchesWithStatus: (status='pending', options={}) ->
    Patches = require '../collections/Patches'
    patches = new Patches()
    options.data ?= {}
    options.data.status = status
    options.url = @urlRoot + '/' + (@get('original') or @id) + '/patches'
    patches.fetch(options)
    return patches

  stringify: -> return JSON.stringify(@toJSON())

  wait: (event) -> new Promise((resolve) => @once(event, resolve))

  fetchLatestVersion: (original, options={}) ->
    options.url = _.result(@, 'urlRoot') + '/' + original + '/version'
    @fetch(options)

module.exports = CocoModel
