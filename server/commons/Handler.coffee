async = require 'async'
mongoose = require 'mongoose'
Grid = require 'gridfs-stream'
errors = require './errors'
log = require 'winston'
Patch = require '../patches/Patch'
User = require '../users/User'
sendwithus = require '../sendwithus'
hipchat = require '../hipchat'
deltasLib = require '../../app/core/deltas'

PROJECT = {original: 1, name: 1, version: 1, description: 1, slug: 1, kind: 1, created: 1, permissions: 1}
FETCH_LIMIT = 1000  # So many ThangTypes

module.exports = class Handler
  # subclasses should override these properties
  modelClass: null
  privateProperties: []
  editableProperties: []
  postEditableProperties: []
  jsonSchema: {}
  waterfallFunctions: []
  allowedMethods: ['GET', 'POST', 'PUT', 'PATCH']

  constructor: ->
    # TODO The second 'or' is for backward compatibility only
    @privateProperties = @modelClass?.privateProperties or @privateProperties or []
    @editableProperties = @modelClass?.editableProperties or @editableProperties or []
    @postEditableProperties = @modelClass?.postEditableProperties or @postEditableProperties or []
    @jsonSchema = @modelClass?.jsonSchema or @jsonSchema or {}

  # subclasses should override these methods
  hasAccess: (req) -> true
  hasAccessToDocument: (req, document, method=null) ->
    return true if req.user?.isAdmin()

    if @modelClass.schema.uses_coco_translation_coverage and (method or req.method).toLowerCase() in ['post', 'put']
      return true if @isJustFillingTranslations(req, document)

    if @modelClass.schema.uses_coco_permissions
      return document.hasPermissionsForMethod?(req.user, method or req.method)
    return true

  isJustFillingTranslations: (req, document) ->
    differ = deltasLib.makeJSONDiffer()
    omissions = ['original'].concat(deltasLib.DOC_SKIP_PATHS)
    delta = differ.diff(_.omit(document.toObject(), omissions), _.omit(req.body, omissions))
    flattened = deltasLib.flattenDelta(delta)
    _.all flattened, (delta) ->
      # sometimes coverage gets moved around... allow other changes to happen to i18nCoverage
      return false unless _.isArray(delta.o)
      return true if 'i18nCoverage' in delta.dataPath
      return false unless delta.o.length is 1
      index = delta.deltaPath.indexOf('i18n')
      return false if index is -1
      return false if delta.deltaPath[index+1] in ['en', 'en-US', 'en-GB']  # English speakers are most likely just spamming, so always treat those as patches, not saves.
      return true

  formatEntity: (req, document) -> document?.toObject()
  getEditableProperties: (req, document) ->
    props = @editableProperties.slice()
    isBrandNew = req.method is 'POST' and not req.body.original
    props = props.concat @postEditableProperties if isBrandNew

    if @modelClass.schema.uses_coco_permissions and req.user
      # can only edit permissions if this is a brand new property,
      # or you are an owner of the old one
      isOwner = document.getAccessForUserObjectId(req.user._id) is 'owner'
      if isBrandNew or isOwner or req.user?.isAdmin()
        props.push 'permissions'

    props.push 'commitMessage' if @modelClass.schema.uses_coco_versions
    props.push 'allowPatches' if @modelClass.schema.is_patchable

    props

  # sending functions
  sendUnauthorizedError: (res) -> errors.unauthorized(res)
  sendForbiddenError: (res) -> errors.forbidden(res)
  sendNotFoundError: (res, message) -> errors.notFound(res, message)
  sendMethodNotAllowed: (res, message) -> errors.badMethod(res, @allowedMethods, message)
  sendBadInputError: (res, message) -> errors.badInput(res, message)
  sendPaymentRequiredError: (res, message) -> errors.paymentRequired(res, message)
  sendDatabaseError: (res, err) ->
    return @sendError(res, err.code, err.response) if err?.response and err?.code
    log.error "Database error, #{err}"
    errors.serverError(res, 'Database error, ' + err)

  sendError: (res, code, message) ->
    errors.custom(res, code, message)

  sendSuccess: (res, message='{}') ->
    res.send 200, message
    res.end()

  sendCreated: (res, message='{}') ->
    res.send 201, message
    res.end()

  sendAccepted: (res, message='{}') ->
    res.send 202, message
    res.end()

  sendNoContent: (res) ->
    res.send 204
    res.end()

  # generic handlers
  get: (req, res) ->
    return @sendForbiddenError(res) if not @hasAccess(req)

    specialParameters = ['term', 'project', 'conditions']

    if @modelClass.schema.uses_coco_translation_coverage and req.query.view is 'i18n-coverage'
      # TODO: generalize view, project, limit and skip query parameters
      projection = {}
      if req.query.project
        projection[field] = 1 for field in req.query.project.split(',')
      query = {slug: {$exists: true}, i18nCoverage: {$exists: true}}
      q = @modelClass.find(query, projection)

      skip = parseInt(req.query.skip)
      if skip? and skip < 1000000
        q.skip(skip)

      limit = parseInt(req.query.limit)
      if limit? and limit < 1000
        q.limit(limit)

      q.exec (err, documents) =>
        return @sendDatabaseError(res, err) if err
        documents = (@formatEntity(req, doc) for doc in documents)
        @sendSuccess(res, documents)

    # If the model uses coco search it's probably a text search
    else if @modelClass.schema.uses_coco_search
      term = req.query.term
      matchedObjects = []
      filters = if @modelClass.schema.uses_coco_versions or @modelClass.schema.uses_coco_permissions then [filter: {index: true}] else [filter: {}]

      skip = parseInt(req.query.skip)
      limit = parseInt(req.query.limit)

      if @modelClass.schema.uses_coco_permissions and req.user
        filters.push {filter: {index: req.user.get('id')}}
      projection = null
      if req.query.project is 'true'
        projection = PROJECT
      else if req.query.project
        if @modelClass.className is 'User'
          projection = PROJECT
          log.warn 'Whoa, we haven\'t yet thought about public properties for User projection yet.'
        else
          projection = {}
          projection[field] = 1 for field in req.query.project.split(',')
      for filter in filters
        callback = (err, results) =>
          return @sendDatabaseError(res, err) if err
          for r in results.results ? results
            obj = r.obj ? r
            continue if obj in matchedObjects  # TODO: probably need a better equality check
            matchedObjects.push obj
          filters.pop()  # doesn't matter which one
          unless filters.length
            res.send matchedObjects
            res.end()
        if term
          filter.filter.$text = $search: term
        else if filters.length is 1 and filters[0].filter?.index is true
          # All we are doing is an empty text search, but that doesn't hit the index, so we'll just look for the slug.
          filter.filter = slug: {$exists: true}
        args = [filter.filter]
        args.push projection if projection
        q = @modelClass.find(args...)
        if skip? and skip < 1000000
          q.skip(skip)
        if limit? and limit < FETCH_LIMIT
          q.limit(limit)
        else
          q.limit(FETCH_LIMIT)
        q.exec callback
    # if it's not a text search but the user is an admin, let him try stuff anyway
    else if req.user?.isAdmin()
      # admins can send any sort of query down the wire
      # Example URL: http://localhost:3000/db/user?filter[anonymous]=true
      filter = {}
      filter[key] = JSON.parse(val) for own key, val of req.query.filter when key not in specialParameters if 'filter' of req.query
      query = @modelClass.find(filter)

      # Conditions are chained query functions, for example: query.find().limit(20).sort('-dateCreated')
      # Example URL: http://localhost:3000/db/user?conditions[limit]=20&conditions[sort]=-dateCreated
      hasLimit = false
      try
        for own key, val of req.query.conditions
          query = query[key](val)
          hasLimit ||= key is 'limit'
      catch e
        return @sendError(res, 422, 'Badly formed conditions.')
      query.limit(2000) unless hasLimit

      query.exec (err, documents) =>
        return @sendDatabaseError(res, err) if err
        documents = (@formatEntity(req, doc) for doc in documents)
        @sendSuccess(res, documents)
    # regular users are only allowed text searches for now, without any additional filters or sorting
    else
      return @sendForbiddenError(res)

  getById: (req, res, id) ->
    return @sendForbiddenError(res) unless @hasAccess(req)
    if req.query.project
      projection = {}
      projection[field] = 1 for field in req.query.project.split(',')
    @getDocumentForIdOrSlug id, projection, (err, document) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless document?
      return @sendForbiddenError(res) unless @hasAccessToDocument(req, document)
      res.setHeader 'Cache-Control', 'no-cache' unless Handler.isID(id + '')  # Don't cache if it's a slug instead of an ID
      @sendSuccess(res, @formatEntity(req, document))

  getByRelationship: (req, res, args...) ->
    # this handler should be overwritten by subclasses
    if @modelClass.schema.is_patchable
      return @getPatchesFor(req, res, args[0]) if req.route.method is 'get' and args[1] is 'patches'
      return @setWatching(req, res, args[0]) if req.route.method is 'put' and args[1] is 'watch'
    return @sendNotFoundError(res)

  getNamesByIDs: (req, res) ->
    ids = req.query.ids or req.body.ids
    if @modelClass.schema.uses_coco_versions
      return @getNamesByOriginals(req, res)
    @getPropertiesFromMultipleDocuments res, User, 'name', ids

  getNamesByOriginals: (req, res, nonVersioned=false) ->
    ids = req.query.ids or req.body.ids
    ids = ids.split(',') if _.isString ids
    ids = _.uniq ids

    # Hack: levels loading thang types need the components returned as well.
    # Need a way to specify a projection for a query.
    project = {name: 1, original: 1, kind: 1, components: 1, prerenderedSpriteSheetData: 1}
    sort = if nonVersioned then {} else {'version.major': -1, 'version.minor': -1}

    makeFunc = (id) =>
      (callback) =>
        criteria = {}
        criteria[if nonVersioned then '_id' else 'original'] = mongoose.Types.ObjectId(id)
        @modelClass.findOne(criteria, project).sort(sort).exec (err, document) ->
          return done(err) if err
          callback(null, document?.toObject() or null)

    funcs = {}
    for id in ids
      return errors.badInput(res, "Given an invalid id: #{id}") unless Handler.isID(id)
      funcs[id] = makeFunc(id)

    async.parallel funcs, (err, results) ->
      return errors.serverError err if err
      res.send (d for d in _.values(results) when d)
      res.end()

  getPatchesFor: (req, res, id) ->
    query =
      $or: [
        {'target.original': id+''}
        {'target.original': mongoose.Types.ObjectId(id)}
      ]
      status: req.query.status or 'pending'
    Patch.find(query).sort('-created').exec (err, patches) =>
      return @sendDatabaseError(res, err) if err
      patches = (patch.toObject() for patch in patches)
      @sendSuccess(res, patches)

  setWatching: (req, res, id) ->
    @getDocumentForIdOrSlug id, (err, document) =>
      return @sendForbiddenError(res) unless @hasAccessToDocument(req, document, 'get')
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless document?
      watchers = document.get('watchers') or []
      me = req.user.get('_id')
      watchers = (l for l in watchers when not l.equals(me))
      watchers.push me if req.body.on and req.body.on isnt 'false'
      document.set 'watchers', watchers
      document.save (err, document) =>
        return @sendDatabaseError(res, err) if err
        @sendSuccess(res, @formatEntity(req, document))

  versions: (req, res, id) ->
    # TODO: a flexible system for doing GAE-like cursors for these sort of paginating queries
    # Keeping it simple for now and just allowing access to the first FETCH_LIMIT results.
    query = {'original': mongoose.Types.ObjectId(id)}
    sort = {'created': -1}
    selectString = 'slug name version commitMessage created creator permissions'
    aggregate = $match: query
    @modelClass.aggregate(aggregate).project(selectString).limit(FETCH_LIMIT).sort(sort).exec (err, results) =>
      return @sendDatabaseError(res, err) if err
      res.send(results)
      res.end()

  files: (req, res, id) ->
    module = req.path[4..].split('/')[0]
    query = {'metadata.path': "db/#{module}/#{id}"}
    Grid.gfs.collection('media').find query, (err, cursor) ->
      return @sendDatabaseError(res, err) if err
      results = cursor.toArray (err, results) ->
        return @sendDatabaseError(res, err) if err
        res.send(results)
        res.end()

  getLatestVersion: (req, res, original, version) ->
    # can get latest overall version, latest of a major version, or a specific version
    return @sendBadInputError(res, 'Invalid MongoDB id: '+original) if not Handler.isID(original)

    query = { 'original': mongoose.Types.ObjectId(original) }
    if version?
      version = version.split('.')
      majorVersion = parseInt(version[0])
      minorVersion = parseInt(version[1])
      query['version.major'] = majorVersion unless _.isNaN(majorVersion)
      query['version.minor'] = minorVersion unless _.isNaN(minorVersion)
    sort = { 'version.major': -1, 'version.minor': -1 }
    args = [query]
    if req.query.project
      projection = {}
      fields = if req.query.project is 'true' then _.keys(PROJECT) else req.query.project.split(',')
      projection[field] = 1 for field in fields
      # Make sure that permissions and version are fetched, but not sent back if they didn't ask for them.
      extraProjectionProps = []
      extraProjectionProps.push 'permissions' unless projection.permissions
      extraProjectionProps.push 'version' unless projection.version
      projection.permissions = 1
      projection.version = 1
      args.push projection
    @modelClass.findOne(args...).sort(sort).exec (err, doc) =>
      return @sendNotFoundError(res) unless doc?
      return @sendForbiddenError(res) unless @hasAccessToDocument(req, doc)
      doc = _.omit doc, extraProjectionProps if extraProjectionProps?
      res.send(doc)
      res.end()

  patch: ->
    console.warn 'Received unexpected PATCH request'
    @put(arguments...)

  put: (req, res, id) ->
    # Client expects PATCH behavior for PUTs
    # Real PATCHs return incorrect HTTP responses in some environments (e.g. Browserstack, schools)
    return @sendForbiddenError(res) if @modelClass.schema.uses_coco_versions and not req.user.isAdmin()  # Campaign editor just saves over things.
    return @sendBadInputError(res, 'No input.') if _.isEmpty(req.body)
    return @sendForbiddenError(res) unless @hasAccess(req)
    @getDocumentForIdOrSlug req.body._id or id, (err, document) =>
      return @sendBadInputError(res, 'Bad id.') if err and err.name is 'CastError'
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless document?
      return @sendForbiddenError(res) unless @hasAccessToDocument(req, document)
      @doWaterfallChecks req, document, (err, document) =>
        return if err is true
        return @sendError(res, err.code, err.res) if err
        @saveChangesToDocument req, document, (err) =>
          return @sendBadInputError(res, err.errors) if err?.valid is false
          return @sendDatabaseError(res, err) if err
          @sendSuccess(res, @formatEntity(req, document))
          @onPutSuccess(req, document)

  post: (req, res) ->
    if @modelClass.schema.uses_coco_versions
      if req.body.original
        return @postNewVersion(req, res)
      else
        return @postFirstVersion(req, res)

    return @sendBadInputError(res, 'No input.') if _.isEmpty(req.body)
    return @sendBadInputError(res, 'id should not be included.') if req.body._id
    return @sendForbiddenError(res) unless @hasAccess(req)
    document = @makeNewInstance(req)
    @saveChangesToDocument req, document, (err) =>
      return @sendBadInputError(res, err.errors) if err?.valid is false
      return @sendDatabaseError(res, err) if err
      @sendSuccess(res, @formatEntity(req, document))
      @onPostSuccess(req, document)

  onPostSuccess: (req, doc) ->
  onPutSuccess: (req, doc) ->

  ###
  TODO: think about pulling some common stuff out of postFirstVersion/postNewVersion
  into a postVersion if we can figure out the breakpoints?
  ..... actually, probably better would be to do the returns with throws instead
  and have a handler which turns them into status codes and messages
  ###
  postFirstVersion: (req, res) ->
    return @sendBadInputError(res, 'No input.') if _.isEmpty(req.body)
    return @sendBadInputError(res, 'id should not be included.') if req.body._id
    return @sendForbiddenError(res) unless @hasAccess(req)
    document = @makeNewInstance(req)
    document.set('original', document._id)
    document.set('creator', req.user._id)
    @saveChangesToDocument req, document, (err) =>
      return @sendBadInputError(res, err.errors) if err?.valid is false
      return @sendDatabaseError(res, err) if err
      @sendSuccess(res, @formatEntity(req, document))

  postNewVersion: (req, res) ->
    """
    To the client, posting new versions look like this:

    POST /db/modelname

    With the input being just the altered structure of the old version,
    leaving the _id property intact even.
    No version object means it's a new major version.
    A version object with a major value means a new minor version.
    All other properties in version are ignored.
    """
    return @sendBadInputError(res, 'This entity is not versioned') unless @modelClass.schema.uses_coco_versions
    return @sendBadInputError(res, 'No input.') if _.isEmpty(req.body)
    return @sendForbiddenError(res) unless @hasAccess(req)
    @getDocumentForIdOrSlug req.body._id, (err, parentDocument) =>
      return @sendBadInputError(res, 'Bad id.') if err and err.name is 'CastError'
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless parentDocument?
      return @sendForbiddenError(res) unless @hasAccessToDocument(req, parentDocument)
      editableProperties = @getEditableProperties req, parentDocument
      updatedObject = parentDocument.toObject()
      for prop in editableProperties
        if (val = req.body[prop])?
          updatedObject[prop] = val
        else if updatedObject[prop]?
          delete updatedObject[prop]
      delete updatedObject._id
      major = req.body.version?.major
      validation = @validateDocumentInput(updatedObject)
      return @sendBadInputError(res, validation.errors) unless validation.valid

      done = (err, newDocument) =>
        return @sendDatabaseError(res, err) if err
        newDocument.set('creator', req.user._id)
        newDocument.save (err) =>
          return @sendDatabaseError(res, err) if err
          @sendSuccess(res, @formatEntity(req, newDocument))
          if @modelClass.schema.is_patchable
            @notifyWatchersOfChange(req.user, newDocument, req.headers['x-current-path'])

      if major?
        parentDocument.makeNewMinorVersion(updatedObject, major, done)

      else
        parentDocument.makeNewMajorVersion(updatedObject, done)

  notifyWatchersOfChange: (editor, changedDocument, editPath) ->
    docLink = "http://codecombat.com#{editPath}"
    @sendChangedHipChatMessage creator: editor, target: changedDocument, docLink: docLink
    watchers = changedDocument.get('watchers') or []
    # Don't send these emails to the person who submitted the patch, or to Nick, George, or Scott.
    watchers = (w for w in watchers when not w.equals(editor.get('_id')) and not (w + '' in ['512ef4805a67a8c507000001', '5162fab9c92b4c751e000274', '51538fdb812dd9af02000001']))
    return unless watchers.length
    User.find({_id:{$in:watchers}}).select({email:1, name:1}).exec (err, watchers) =>
      for watcher in watchers
        @notifyWatcherOfChange editor, watcher, changedDocument, editPath

  notifyWatcherOfChange: (editor, watcher, changedDocument, editPath) ->
    context =
      email_id: sendwithus.templates.change_made_notify_watcher
      recipient:
        address: watcher.get('email')
        name: watcher.get('name')
      email_data:
        doc_name: changedDocument.get('name') or '???'
        submitter_name: editor.get('name') or '???'
        doc_link: if editPath then "http://codecombat.com#{editPath}" else null
        commit_message: changedDocument.get('commitMessage')
    sendwithus.api.send context, (err, result) ->

  sendChangedHipChatMessage: (options) ->
    message = "#{options.creator.get('name')} saved a change to <a href=\"#{options.docLink}\">#{options.target.get('name')}</a>: #{options.target.get('commitMessage') or '(no commit message)'}"
    rooms = if /Diplomat submission/.test(message) then ['main'] else ['main', 'artisans']
    hipchat.sendHipChatMessage message, rooms

  makeNewInstance: (req) ->
    model = new @modelClass({})
    if @modelClass.schema.is_patchable
      watchers = [req.user.get('_id')]
      if req.user.isAdmin()  # https://github.com/codecombat/codecombat/issues/1105
        nick = mongoose.Types.ObjectId('512ef4805a67a8c507000001')
        watchers.push nick unless _.find watchers, (id) -> id.equals nick
      model.set 'watchers', watchers
    model

  validateDocumentInput: (input) ->
    tv4 = require('tv4').tv4
    res = tv4.validateMultiple(input, @jsonSchema)
    res

  @isID: (id) -> _.isString(id) and id.length is 24 and id.match(/[a-f0-9]/gi)?.length is 24

  getDocumentForIdOrSlug: (idOrSlug, projection, done) ->
    unless done
      done = projection  # projection is optional argument
      projection = null
    idOrSlug = idOrSlug+''
    if Handler.isID(idOrSlug)
      query = @modelClass.findById(idOrSlug)
    else
      query = @modelClass.findOne {slug: idOrSlug}
    query.select projection if projection
    query.exec (err, document) ->
      done(err, document)

  doWaterfallChecks: (req, document, done) ->
    return done(null, document) unless @waterfallFunctions.length

    # waterfall doesn't let you pass an initial argument
    # so wrap the first waterfall function to pass in the document
    funcs = (f for f in @waterfallFunctions)
    firstFunc = funcs[0]
    wrapped = (func, r, doc) -> (callback) -> func(r, doc, callback)
    funcs[0] = wrapped(firstFunc, req, document)
    async.waterfall funcs, (err, rrr, document) ->
      done(err, document)

  saveChangesToDocument: (req, document, done) ->
    for prop in @getEditableProperties req, document
      if (val = req.body[prop])?
        document.set prop, val
      # Hold on, gotta think about that one
      #else if document.get(prop)? and req.method isnt 'PATCH'
      #  document.set prop, 'undefined'
    obj = document.toObject()

    # Hack to get saving of Users to work. Probably should replace these props with strings
    # so that validation doesn't get hung up on Date objects in the documents.
    delete obj.dateCreated

    validation = @validateDocumentInput(obj)
    return done(validation) unless validation.valid

    document.save (err) -> done(err)

  getPropertiesFromMultipleDocuments: (res, model, properties, ids) ->
    query = model.find()
    ids = ids.split(',') if _.isString ids
    ids = _.uniq ids
    for id in ids
      return errors.badInput(res, "Given an invalid id: #{id}") unless Handler.isID(id)
    query.where({'_id': { $in: ids} })
    query.select(properties).exec (err, documents) ->
      dict = {}
      _.each documents, (document) ->
        dict[document.id] = document
      res.send dict
      res.end()

  delete: (req, res) -> @sendMethodNotAllowed res, 'DELETE not allowed.'

  head: (req, res) -> @sendMethodNotAllowed res, 'HEAD not allowed.'

  # This is not a Mongoose user
  projectionForUser: (req, model, ownerID) ->
    return {} if 'privateProperties' not of model or req.user?._id + '' is ownerID + '' or req.user.isAdmin()
    projection = {}
    projection[field] = 0 for field in model.privateProperties
    projection
