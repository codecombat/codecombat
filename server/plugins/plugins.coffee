mongoose = require('mongoose')
log = require 'winston'
utils = require '../lib/utils'

module.exports.MigrationPlugin = (schema, migrations) ->
  # Property name migrations made EZ
  # This is for just when you want one property to be named differently

  # 1. Change the schema and the client/server logic to use the new name
  # 2. Add this plugin to the target models, passing in a dictionary of old/new names.
  # 3. Check that tests still run, deploy to production.
  # 4. Run db.<collection>.update({}, {$rename: {'<oldname>': '<newname>'}}, {multi: true}) on the server
  # 5. Remove the names you added to the migrations dictionaries for the next deploy

  schema.post 'init', ->
    for oldKey in _.keys migrations
      val = @get oldKey
      @set oldKey, undefined
      continue if val is undefined
      newKey = migrations[oldKey]
      @set newKey, val

module.exports.PatchablePlugin = (schema) ->
  schema.is_patchable = true
  schema.index({'target.original': 1, 'status': '1', 'created': -1})

RESERVED_NAMES = ['names']

module.exports.NamedPlugin = (schema) ->
  schema.uses_coco_names = true
  schema.add({name: String, slug: String})
  schema.index({'slug': 1}, {unique: true, sparse: true, name: 'slug index'})

  schema.statics.findBySlug = (slug, done) ->
    @findOne {slug: slug}, done

  schema.statics.findBySlugOrId = (slugOrID, done) ->
    return @findById slugOrID, done if utils.isID slugOrID
    @findOne {slug: slugOrID}, done

  schema.pre('save', (next) ->
    if schema.uses_coco_versions
      v = @get('version')
      return next() unless v.isLatestMajor and v.isLatestMinor

    newSlug = _.str.slugify(@get('name'))
    if newSlug in RESERVED_NAMES
      err = new Error('Reserved name.')
      err.response = {message: ' is a reserved name', property: 'name'}
      err.code = 422
      return next(err)
    if newSlug not in [@get('slug'), ''] and not @get 'anonymous'
      @set('slug', newSlug)
      @checkSlugConflicts(next)
    else if newSlug is '' and @get 'slug'
      @set 'slug', undefined
      next()
    else
      next()
  )

  schema.methods.checkSlugConflicts = (done) ->
    slug = @get('slug')

    if slug.length is 24 and slug.match(/[a-f0-9]/gi)?.length is 24
      err = new Error('Bad name.')
      err.response = {message: 'cannot be like a MongoDB ID, Mr. Hacker.', property: 'name'}
      err.code = 422
      done(err)

    query = {slug: slug}

    if @get('original')
      query.original = {'$ne': @original}
    else if @_id
      query._id = {'$ne': @_id}

    @model(@constructor.modelName).count query, (err, count) ->
      if count
        err = new Error('Slug conflict.')
        err.response = {message: 'is already in use', property: 'name'}
        err.code = 409
        done(err)
      done()

module.exports.PermissionsPlugin = (schema) ->
  schema.uses_coco_permissions = true

  PermissionSchema = new mongoose.Schema
    target: mongoose.Schema.Types.Mixed
    access: {type: String, 'enum': ['read', 'write', 'owner']}
  , {id: false, _id: false}

  schema.add(permissions: [PermissionSchema])

  schema.pre 'save', (next) ->
    return next() if @getOwner()
    err = new Error('Permissions needs an owner.')
    err.response = {message: 'needs an owner.', property: 'permissions'}
    err.code = 409
    next(err)

  schema.methods.hasPermissionsForMethod = (actor, method) ->
    method = method.toLowerCase()
    # method is 'get', 'put', 'patch', 'post', or 'delete'
    # actor is a User object

    allowed =
      get: ['read', 'write', 'owner']
      put: ['write', 'owner']
      patch: ['write', 'owner']
      post: ['write', 'owner'] # used to post new versions of something
      delete: [] # nothing may go!

    allowed = allowed[method] or []

    for permission in @permissions
      if permission.target is 'public' or actor?._id.equals(permission.target)
        return true if permission.access in allowed

    return false

  schema.methods.getOwner = ->
    for permission in @permissions
      if permission.access is 'owner'
        return permission.target

  schema.methods.getPublicAccess = ->
    for permission in @permissions
      if permission.target is 'public'
        return permission.access

  schema.methods.getAccessForUserObjectId = (objectId) ->
    public_access = null
    for permission in @permissions
      if permission.target is 'public'
        public_access = permission.access
        continue
      if objectId.equals(permission.target)
        return permission.access
    return public_access

module.exports.VersionedPlugin = (schema) ->
  schema.uses_coco_versions = true

  schema.add(
    version:
      major: {type: Number, 'default': 0}
      minor: {type: Number, 'default': 0}
      isLatestMajor: {type: Boolean, 'default': true}
      isLatestMinor: {type: Boolean, 'default': true}
    original: {type: mongoose.Schema.ObjectId, ref: @modelName}
    parent: {type: mongoose.Schema.ObjectId, ref: @modelName}
    creator: {type: mongoose.Schema.ObjectId, ref: 'User'}
    created: {type: Date, 'default': Date.now}
    commitMessage: {type: String}
  )

  # Prevent multiple documents with the same version
  # Also used for looking up latest version, or specific versions.
  schema.index({'original': 1, 'version.major': -1, 'version.minor': -1}, {unique: true, name: 'version index'})

  schema.statics.getLatestMajorVersion = (original, options, done) ->
    options = options or {}
    query = @findOne({original: original, 'version.isLatestMajor': true})
    query.select(options.select) if options.select
    query.exec((err, latest) =>
      return done(err) if err
      return done(null, latest) if latest

      # handle the case where no version is marked as the latest
      q = @find({original: original})
      q.sort({'version.major': -1, 'version.minor': -1})
      q.select(options.select) if options.select
      q.limit(1)
      q.exec((err, latest) =>
        return done(err) if err
        return done(null, null) if latest.length is 0
        latest = latest[0]

        # don't fix missing versions by default. In all likelihood, it's about to change anyway
        if options.autofix # not used
          latest.version.isLatestMajor = true
          latest.version.isLatestMinor = true
          latestObject = latest.toObject()
          @update({_id: latest._id}, {version: latestObject.version})
        done(null, latest)
      )
    )

  schema.statics.getLatestMinorVersion = (original, majorVersion, options, done) ->
    options = options or {}
    query = @findOne({original: original, 'version.isLatestMinor': true, 'version.major': majorVersion})
    query.select(options.select) if options.select
    query.exec((err, latest) =>
      return done(err) if err
      return done(null, latest) if latest
      q = @find({original: original, 'version.major': majorVersion})
      q.sort({'version.minor': -1})
      q.select(options.select) if options.select
      q.limit(1)
      q.exec((err, latest) ->
        return done(err) if err
        return done(null, null) if latest.length is 0
        latest = latest[0]

        if options.autofix # not used
          latestObject = latest.toObject()
          latestObject.version.isLatestMajor = true
          latestObject.version.isLatestMinor = true
          @update({_id: latest._id}, {version: latestObject.version})
        done(null, latest)
      )
    )

  schema.methods.makeNewMajorVersion = (newObject, done) ->
    Model = @model(@constructor.modelName)

    latest = Model.getLatestMajorVersion(@original, {select: 'version'}, (err, latest) =>
      return done(err) if err

      updatedObject = _.cloneDeep latestObject
      # unmark the current latest major version in the database
      latestObject = latest.toObject()
      latestObject.version.isLatestMajor = false
      Model.update({_id: latest._id}, {version: latestObject.version, $unset: {index: 1, slug: 1}}, {}, (err) =>
        return done(err) if err

        newObject['version'] = {major: latest.version.major + 1}
        newObject.index = true
        newObject.parent = @_id
        delete newObject['_id']
        delete newObject['created']
        done(null, new Model(newObject))
      )
    )

  schema.methods.makeNewMinorVersion = (newObject, majorVersion, done) ->
    Model = @model(@constructor.modelName)

    latest = Model.getLatestMinorVersion(@original, majorVersion, {select: 'version'}, (err, latest) =>
      return done(err) if err

      # unmark the current latest major version in the database
      latestObject = latest.toObject()
      wasLatestMajor = latestObject.version.isLatestMajor
      latestObject.version.isLatestMajor = false
      latestObject.version.isLatestMinor = false
      Model.update({_id: latest._id}, {version: latestObject.version, $unset: {index: 1, slug: 1}}, {}, (err) =>
        return done(err) if err

        newObject['version'] =
          major: latest.version.major
          minor: latest.version.minor + 1
          isLatestMajor: wasLatestMajor
        if wasLatestMajor
          newObject.index = true
        else
          delete newObject.index if newObject.index?
          delete newObject.slug if newObject.slug?
        newObject.parent = @_id
        delete newObject['_id']
        delete newObject['created']
        done(null, new Model(newObject))
      )
    )

  # Assume every save is a new version, hence an edit
  schema.pre 'save', (next) ->
    User = require '../models/User'  # Avoid mutual inclusion cycles
    userID = @get('creator')?.toHexString()
    return next() unless userID?

    statName = User.statsMapping.edits[@constructor.modelName]
    User.incrementStat userID, statName, next

module.exports.SearchablePlugin = (schema, options) ->
  # this plugin must be added only after the others (specifically Versioned and Permissions)
  # have been added, as how it builds the text search index depends on which of those are used.

  searchable = options.searchable
  unless searchable
    throw new Error('SearchablePlugin options must include list of searchable properties.')

  index = {}

  schema.uses_coco_search = true
  if schema.uses_coco_versions or schema.uses_coco_permissions
    index['index'] = 1
    schema.add(index: mongoose.Schema.Types.Mixed)

  index[prop] = 'text' for prop in searchable

  # should now have something like {'index': 1, name: 'text', body: 'text'}
  schema.index(index, {sparse: true, name: 'search index', language_override: 'searchLanguage'})

  schema.pre 'save', (next) ->
    # never index old versions, index plugin handles un-indexing old versions
    if schema.uses_coco_versions and ((not @version.isLatestMajor) or (not @version.isLatestMinor))
      return next()

    @index = true
    if schema.uses_coco_permissions
      access = @getPublicAccess()
      @index = @getOwner() unless access

    next()

module.exports.TranslationCoveragePlugin = (schema, options) ->

  schema.uses_coco_translation_coverage = true
  schema.set('autoIndex', true)

  index = {}

  if schema.uses_coco_versions
    if not schema.uses_coco_names
      throw Error('If using translation coverage and versioning, should also use names for indexing.')
    index.slug = 1

  index.i18nCoverage = 1

  schema.index(index, {sparse: true, name: 'translation coverage index', background: true})
