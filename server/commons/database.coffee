config = require '../../server_config'
winston = require 'winston'
mongoose = require 'mongoose'
Grid = require 'gridfs-stream'
mongooseCache = require 'mongoose-cache'
errors = require '../commons/errors'
Promise = require 'bluebird'
_ = require 'lodash'
co = require 'co'

module.exports =
  isID: (id) -> _.isString(id) and id.length is 24 and id.match(/[a-f0-9]/gi)?.length is 24
  
  connect: () ->
    address = module.exports.generateMongoConnectionString()
    winston.info "Connecting to Mongo with connection string #{address}, readpref: #{config.mongo.readpref}"
  
    mongoose.connect address
    mongoose.connection.once 'open', -> Grid.gfs = Grid(mongoose.connection.db, mongoose.mongo)
  
    # Hack around Mongoose not exporting Aggregate so that we can patch its exec, too
    # https://github.com/LearnBoost/mongoose/issues/1910
    Level = require '../models/Level'
    Aggregate = Level.aggregate().constructor
    maxAge = (Math.random() * 10 + 10) * 60 * 1000  # Randomize so that each server doesn't refresh cache from db at same times
    mongooseCache.install(mongoose, {max: 1000, maxAge: maxAge, debug: false}, Aggregate)

  generateMongoConnectionString: ->
    if not global.testing and config.mongo.mongoose_replica_string
      address = config.mongo.mongoose_replica_string
    else
      dbName = config.mongo.db
      dbName += '_unittest' if global.testing
      address = config.mongo.host + ':' + config.mongo.port
      if config.mongo.username and config.mongo.password
        address = config.mongo.username + ':' + config.mongo.password + '@' + address
      address = "mongodb://#{address}/#{dbName}"
  
    return address

  initDoc: (req, Model) ->
    # TODO: Move to model superclass or plugins?
    doc = new Model({})

    if Model.schema.is_patchable
      watchers = [req.user.get('_id')]
      if req.user.isAdmin()  # https://github.com/codecombat/codecombat/issues/1105
        nick = mongoose.Types.ObjectId('512ef4805a67a8c507000001')
        watchers.push nick unless _.find watchers, (id) -> id.equals nick
      doc.set 'watchers', watchers

    if Model.schema.uses_coco_versions
      doc.set('original', doc._id)
      doc.set('creator', req.user._id)

    return doc

  applyCustomSearchToDBQ: (req, dbq) ->
    specialParameters = ['term', 'project', 'conditions']

    return unless req.user?.isAdmin()
    return unless req.query.filter or req.query.conditions

    # admins can send any sort of query down the wire
    # Example URL: http://localhost:3000/db/user?filter[anonymous]=true
    filter = {}
    if 'filter' of req.query
      for own key, val of req.query.filter
        if key not in specialParameters
          try
            filter[key] = JSON.parse(val)
          catch SyntaxError
            throw new errors.UnprocessableEntity("Could not parse filter for key '#{key}'.")
    dbq.find(filter)

    # Conditions are chained query functions, for example: query.find().limit(20).sort('-dateCreated')
    # Example URL: http://localhost:3000/db/user?conditions[limit]=20&conditions[sort]="-dateCreated"
    for own key, val of req.query.conditions
      if not dbq[key]
        throw new errors.UnprocessableEntity("No query condition '#{key}'.")
      try
        val = JSON.parse(val)
        dbq[key](val)
      catch SyntaxError
        throw new errors.UnprocessableEntity("Could not parse condition for key '#{key}'.")


  viewSearch: Promise.promisify (dbq, req, done) ->
    Model = dbq.model
    # TODO: Make this function only alter dbq or returns a find. It should not also execute the query.
    term = req.query.term
    matchedObjects = []
    filters = if Model.schema.uses_coco_versions or Model.schema.uses_coco_permissions then [filter: {index: true}] else [filter: {}]

    if Model.schema.uses_coco_permissions and req.user
      filters.push {filter: {index: req.user.get('id')}}

    for filter in filters
      callback = (err, results) ->
        return done(new errors.InternalServerError('Error fetching search results.', {err: err})) if err
        for r in results.results ? results
          obj = r.obj ? r
          continue if obj in matchedObjects  # TODO: probably need a better equality check
          continue if obj.get('restricted') and not req.user?.isAdmin() and not (obj.get('restricted') is 'code-play' and req.features.codePlay)
          matchedObjects.push obj
        filters.pop()  # doesn't matter which one
        unless filters.length
          done(null, matchedObjects)

      if term
        filter.filter.$text = $search: term
      else if filters.length is 1 and filters[0].filter?.index is true
        # All we are doing is an empty text search, but that doesn't hit the index,
        # so we'll just look for the slug.
        filter.filter = slug: {$exists: true}

      # This try/catch is here to handle when a custom search tries to find by slug. TODO: Fix this more gracefully.
      try
        dbq.find filter.filter
      catch
      dbq.exec callback


  assignBody: (req, doc, options={}) ->
    if not req.body
      throw new errors.UnprocessableEntity('No input')
      
    if not doc.schema.statics.editableProperties
      console.warn 'No editableProperties set for', doc.constructor.modelName
    props = (doc.schema.statics.editableProperties or []).slice()

    if doc.isNew
      props = props.concat(doc.schema.statics.postEditableProperties or [])
      if not doc.schema.statics.postEditableProperties
        console.warn 'No postEditableProperties set for', doc.constructor.modelName

    if doc.schema.uses_coco_permissions and req.user
      isOwner = doc.getAccessForUserObjectId(req.user._id) is 'owner'
      if doc.isNew or isOwner or req.user?.isAdmin()
        props.push 'permissions'

    props.push 'commitMessage' if doc.schema.uses_coco_versions
    props.push 'allowPatches' if doc.schema.is_patchable

    for prop in props
      if (val = req.body[prop])?
        doc.set prop, val
      else if options.unsetMissing and doc.get(prop)?
        doc.set prop, undefined


  validateDoc: (doc) ->
    obj = doc.toObject()
    # Hack to get saving of Users to work. Probably should replace these props with strings
    # so that validation doesn't get hung up on Date objects in the documents.
    delete obj.dateCreated
    tv4 = require('tv4').tv4
    result = tv4.validateMultiple(obj, doc.schema.statics.jsonSchema)
    if not result.valid
      prunedErrors = (_.omit(error, 'stack') for error in result.errors)
      winston.debug('Validation errors: ', JSON.stringify(prunedErrors, null, '\t'))
      throw new errors.UnprocessableEntity('JSON-schema validation failed', { validationErrors: result.errors })


  getDocFromHandle: co.wrap (req, Model, options={}) ->
    dbq = Model.find()
    handleName = options.handleName or 'handle'
    handle = req.params[handleName]
    if not handle
      return done(new errors.UnprocessableEntity('No handle provided.'))
    if @isID(handle)
      dbq.findOne({ _id: handle })
    else
      dbq.findOne({ slug: handle })
      
    if options.select
      dbq.select(options.select)

    doc = yield dbq.exec()
    if options.getLatest and Model.schema.uses_coco_versions and doc and not doc.get('version.isLatestMajor')
      original = doc.get('original')
      doc = yield Model.findOne({original}).sort({ 'version.major': -1, 'version.minor': -1 })
    return doc


  hasAccessToDocument: (req, doc, method) ->
    method = method or req.method
    return true if req.user?.isAdmin()

    if doc.schema.uses_coco_translation_coverage and method in ['post', 'put']
      return true if @isJustFillingTranslations(req, doc)

    if doc.schema.uses_coco_permissions
      return doc.hasPermissionsForMethod?(req.user, method)
    return true

  isJustFillingTranslations: (req, doc) ->
    deltasLib = require '../../app/core/deltas'
    differ = deltasLib.makeJSONDiffer()
    omissions = ['original'].concat(deltasLib.DOC_SKIP_PATHS)
    delta = differ.diff(_.omit(doc.toObject(), omissions), _.omit(req.body, omissions))
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
