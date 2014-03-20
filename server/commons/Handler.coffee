async = require 'async'
mongoose = require('mongoose')
Grid = require 'gridfs-stream'
errors = require './errors'
PROJECT = {original:1, name:1, version:1, description: 1, slug:1, kind: 1}
FETCH_LIMIT = 150

module.exports = class Handler
  # subclasses should override these properties
  modelClass: null
  editableProperties: []
  postEditableProperties: []
  jsonSchema: {}
  waterfallFunctions: []

  # subclasses should override these methods
  hasAccess: (req) -> true
  hasAccessToDocument: (req, document, method=null) ->
    return true if req.user?.isAdmin()
    if @modelClass.schema.uses_coco_permissions
      return document.hasPermissionsForMethod(req.user, method or req.method)
    return true

  formatEntity: (req, document) -> document?.toObject()
  getEditableProperties: (req, document) ->
    props = @editableProperties.slice()
    isBrandNew = req.method is 'POST' and not req.body.original
    if isBrandNew
      props = props.concat @postEditableProperties

    if @modelClass.schema.uses_coco_permissions
      # can only edit permissions if this is a brand new property,
      # or you are an owner of the old one
      isOwner = document.getAccessForUserObjectId(req.user._id) is 'owner'
      if isBrandNew or isOwner or req.user?.isAdmin()
        props.push 'permissions'

    if @modelClass.schema.uses_coco_versions
      props.push 'commitMessage'

    props

  # sending functions
  sendUnauthorizedError: (res) -> errors.forbidden(res) #TODO: rename sendUnauthorizedError to sendForbiddenError
  sendNotFoundError: (res) -> errors.notFound(res)
  sendMethodNotAllowed: (res) -> errors.badMethod(res)
  sendBadInputError: (res, message) -> errors.badInput(res, message)
  sendDatabaseError: (res, err) -> errors.serverError(res, 'Database error, ' + err)

  sendError: (res, code, message) ->
    errors.custom(res, code, message)

  sendSuccess: (res, message) ->
    res.send(message)
    res.end()

  # generic handlers
  get: (req, res) ->
    # by default, ordinary users never get unfettered access to the database
    return @sendUnauthorizedError(res) unless req.user?.isAdmin()

    # admins can send any sort of query down the wire, though
    conditions = JSON.parse(req.query.conditions || '[]')
    query = @modelClass.find()

    try
      for condition in conditions
        name = condition[0]
        f = query[name]
        args = condition[1..]
        query = query[name](args...)
    catch e
      return @sendError(res, 422, 'Badly formed conditions.')

    query.exec (err, documents) =>
      return @sendDatabaseError(res, err) if err
      documents = (@formatEntity(req, doc) for doc in documents)
      @sendSuccess(res, documents)

  getById: (req, res, id) ->
    return @sendUnauthorizedError(res) unless @hasAccess(req)

    @getDocumentForIdOrSlug id, (err, document) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless document?
      return @sendUnauthorizedError(res) unless @hasAccessToDocument(req, document)
      @sendSuccess(res, @formatEntity(req, document))

  getByRelationship: (req, res, args...) ->
    # this handler should be overwritten by subclasses
    return @sendNotFoundError(res)

  search: (req, res) ->
    unless @modelClass.schema.uses_coco_search
      return @sendNotFoundError(res)

    term = req.query.term
    matchedObjects = []
    filters = [{filter: {index: true}}]
    if @modelClass.schema.uses_coco_permissions and req.user
      filters.push {filter: {index: req.user.get('id')}}
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
        filter.project = PROJECT if req.query.project
        @modelClass.textSearch term, filter, callback
      else
        args = [filter.filter]
        args.push PROJECT if req.query.project
        @modelClass.find(args...).limit(FETCH_LIMIT).exec callback

  versions: (req, res, id) ->
    # TODO: a flexible system for doing GAE-like cursors for these sort of paginating queries
    # Keeping it simple for now and just allowing access to the first FETCH_LIMIT results.
    query = {'original': mongoose.Types.ObjectId(id)}
    sort = {'created': -1}
    selectString = 'slug name version commitMessage created permissions'  # Is this even working?
    @modelClass.find(query).select(selectString).limit(FETCH_LIMIT).sort(sort).exec (err, results) =>
      return @sendDatabaseError(res, err) if err
      for doc in results
        return @sendUnauthorizedError(res) unless @hasAccessToDocument(req, doc)
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
    query = { 'original': mongoose.Types.ObjectId(original) }
    if version?
      version = version.split('.')
      majorVersion = parseInt(version[0])
      minorVersion = parseInt(version[1])
      query['version.major'] = majorVersion unless _.isNaN(majorVersion)
      query['version.minor'] = minorVersion unless _.isNaN(minorVersion)
    sort = { 'version.major': -1, 'version.minor': -1 }
    args = [query]
    args.push PROJECT if req.query.project
    @modelClass.findOne(args...).sort(sort).exec (err, doc) =>
      return @sendNotFoundError(res) unless doc?
      return @sendUnauthorizedError(res) unless @hasAccessToDocument(req, doc)
      res.send(doc)
      res.end()

  patch: ->
    @put(arguments...)

  put: (req, res, id) ->
    return @postNewVersion(req, res) if @modelClass.schema.uses_coco_versions
    return @sendBadInputError(res, 'No input.') if _.isEmpty(req.body)
    return @sendUnauthorizedError(res) unless @hasAccess(req)
    @getDocumentForIdOrSlug req.body._id or id, (err, document) =>
      return @sendBadInputError(res, 'Bad id.') if err and err.name is 'CastError'
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless document?
      return @sendUnauthorizedError(res) unless @hasAccessToDocument(req, document)
      @doWaterfallChecks req, document, (err, document) =>
        return @sendError(res, err.code, err.res) if err
        @saveChangesToDocument req, document, (err) =>
          return @sendBadInputError(res, err.errors) if err?.valid is false
          return @sendDatabaseError(res, err) if err
          @sendSuccess(res, @formatEntity(req, document))

  post: (req, res) ->
    if @modelClass.schema.uses_coco_versions
      if req.body.original
        return @postNewVersion(req, res)
      else
        return @postFirstVersion(req, res)

    return @sendBadInputError(res, 'No input.') if _.isEmpty(req.body)
    return @sendBadInputError(res, 'id should not be included.') if req.body._id
    return @sendUnauthorizedError(res) unless @hasAccess(req)
    validation = @validateDocumentInput(req.body)
    return @sendBadInputError(res, validation.errors) unless validation.valid
    document = @makeNewInstance(req)
    @saveChangesToDocument req, document, (err) =>
      return @sendDatabaseError(res, err) if err
      @sendSuccess(res, @formatEntity(req, document))

  ###
  TODO: think about pulling some common stuff out of postFirstVersion/postNewVersion
  into a postVersion if we can figure out the breakpoints?
  ..... actually, probably better would be to do the returns with throws instead
  and have a handler which turns them into status codes and messages
  ###
  postFirstVersion: (req, res) ->
    return @sendBadInputError(res, 'No input.') if _.isEmpty(req.body)
    return @sendBadInputError(res, 'id should not be included.') if req.body._id
    return @sendUnauthorizedError(res) unless @hasAccess(req)
    validation = @validateDocumentInput(req.body)
    return @sendBadInputError(res, validation.errors) unless validation.valid
    document = @makeNewInstance(req)
    document.set('original', document._id)
    document.set('creator', req.user._id)
    @saveChangesToDocument req, document, (err) =>
      return @sendBadInputError(res, err.response) if err?.response
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
    return @sendUnauthorizedError(res) unless @hasAccess(req)
    validation = @validateDocumentInput(req.body)
    return @sendBadInputError(res, validation.errors) unless validation.valid
    @getDocumentForIdOrSlug req.body._id, (err, parentDocument) =>
      return @sendBadInputError(res, 'Bad id.') if err and err.name is 'CastError'
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless parentDocument?
      sort = { 'version.major': -1, 'version.minor': -1 }
      query = { 'original': mongoose.Types.ObjectId(req.body._id) }
      @modelClass.findOne(query).sort(sort).exec (err, doc) =>
        return @sendUnauthorizedError(res) unless @hasAccessToDocument(req, doc)
        updatedObject = parentDocument.toObject()
        changes = _.pick req.body, @getEditableProperties(req, parentDocument)
        _.extend updatedObject, changes
        delete updatedObject._id
        major = req.body.version?.major

        done = (err, newDocument) =>
          return @sendDatabaseError(res, err) if err
          newDocument.set('creator', req.user._id)
          newDocument.save (err) =>
            return @sendDatabaseError(res, err) if err
            @sendSuccess(res, @formatEntity(req, newDocument))

        if major?
          parentDocument.makeNewMinorVersion(updatedObject, major, done)

        else
          parentDocument.makeNewMajorVersion(updatedObject, done)

  makeNewInstance: (req) ->
    new @modelClass({})

  validateDocumentInput: (input) ->
    tv4 = require('tv4').tv4
    res = tv4.validateMultiple(input, @jsonSchema)
    res

  @isID: (id) -> _.isString(id) and id.length is 24 and id.match(/[a-z0-9]/gi)?.length is 24

  getDocumentForIdOrSlug: (idOrSlug, done) ->
    idOrSlug = idOrSlug+''
    if Handler.isID(idOrSlug)
      @modelClass.findById(idOrSlug).exec (err, document) ->
        done(err, document)
    else
      @modelClass.findOne {slug: idOrSlug}, (err, document) ->
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
    for prop in @getEditableProperties(req, document)
      document.set(prop, req.body[prop]) if req.body[prop]?
    obj = document.toObject()

    # Hack to get saving of Users to work. Probably should replace these props with strings
    # so that validation doesn't get hung up on Date objects in the documents.
    delete obj.dateCreated

    validation = @validateDocumentInput(obj)
    return done(validation) unless validation.valid

    document.save (err) -> done(err)
