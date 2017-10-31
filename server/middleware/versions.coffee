utils = require '../lib/utils'
errors = require '../commons/errors'
_ = require 'lodash'
wrap = require 'co-express'
mongoose = require 'mongoose'
database = require '../commons/database'
parse = require '../commons/parse'
{ notifyChangesMadeToDoc } = require '../commons/notify'

# More info on database versioning: https://github.com/codecombat/codecombat/wiki/Versioning

exports.postNewVersion = (Model, options={}) -> wrap (req, res) ->
  # Find the document which is getting a new version
  parent = yield database.getDocFromHandle(req, Model)
  if not parent
    throw new errors.NotFound('Parent not found.')
    
  # Check permissions
  # TODO: Figure out an encapsulated way to do this; it's more permissions than versioning
  if options.hasPermissionsOrTranslations
    permissions = options.hasPermissionsOrTranslations
    permissions = [permissions] if _.isString(permissions)
    permissions = ['admin'] if not _.isArray(permissions)
    hasPermission = _.any(req.user?.hasPermission(permission) for permission in permissions)
    if Model.schema.uses_coco_permissions and not hasPermission
      hasPermission = parent.hasPermissionsForMethod(req.user, req.method)
    if not (hasPermission or database.isJustFillingTranslations(req, parent))
      throw new errors.Forbidden()

  # Create the new version, a clone of the parent with POST data applied
  Model = parent.constructor
  doc = database.initDoc(req, Model)
  exports.initNewVersion(doc, parent)
  database.assignBody(req, doc, { unsetMissing: true })
  major = req.body.version?.major
  yield exports.saveNewVersion(doc, major)
  notifyChangesMadeToDoc(req, doc)
  res.status(201).send(doc.toObject())


exports.initNewVersion = (doc, parent) ->
  # makes a (mostly) copy of the parent document
  ATTRIBUTES_NOT_INHERITED = ['_id', 'version', 'created', 'creator']
  doc.set(_.omit(parent.toObject(), ATTRIBUTES_NOT_INHERITED))
  return doc
    

exports.saveNewVersion = wrap (doc, major=null) ->
  # Given a document created by initNewVersion and then modified, this sets its versions and updates existing
  # versions accordingly.
  
  Model = doc.constructor

  # Get latest (minor or major) version. This may not be the same document (or same major version) as parent.
  latestSelect = 'version index slug'
  original = doc.get('original')
  if _.isNumber(major)
    q1 = Model.findOne({original: original, 'version.isLatestMinor': true, 'version.major': major})
  else
    q1 = Model.findOne({original: original, 'version.isLatestMajor': true})
  q1.select latestSelect
  latest = yield q1.exec()

  # Handle the case where no version is marked as latest, since making new
  # versions is not atomic
  if not latest
    if _.isNumber(major)
      q2 = Model.findOne({original: original, 'version.major': major})
      q2.sort({'version.minor': -1})
    else
      q2 = Model.findOne()
      q2.sort({'version.major': -1, 'version.minor': -1})
    q2.select(latestSelect)
    latest = yield q2.exec()
    if not latest
      throw new errors.NotFound('Previous version not found.')

  # Update the latest version, making it no longer the latest.
  version = _.clone(latest.get('version'))
  wasLatestMajor = version.isLatestMajor
  version.isLatestMajor = false
  if _.isNumber(major)
    version.isLatestMinor = false
  raw = yield latest.update({$set: {version: version}, $unset: {index: 1, slug: 1}})
  if not raw.nModified
    console.error('Doc', doc)
    console.error('Raw response', raw)
    throw new errors.InternalServerError('Latest version could not be modified.')

  # update the new doc with version, index information
  # Relying heavily on Mongoose schema default behavior here. TODO: Make explicit?
  if _.isNumber(major)
    doc.set({
      'version.major': latest.version.major
      'version.minor': latest.version.minor + 1
      'version.isLatestMajor': wasLatestMajor
    })
    if wasLatestMajor
      doc.set('index', true)
    else
      doc.set({index: undefined, slug: undefined})
  else
    doc.set('version.major', latest.version.major + 1)
    doc.set('index', true)

  doc.set('parent', latest._id)

  try
    doc = yield doc.save()
  catch e
    # Revert changes to latest doc made earlier, should set everything back to normal
    yield latest.update({$set: _.pick(latest.toObject(), 'version', 'index', 'slug')})
    throw e
    
  return doc
  
    
exports.getLatestVersion = (Model, options={}) -> wrap (req, res) ->
  # can get latest overall version, latest of a major version, or a specific version
  original = req.params.handle
  version = req.params.version
  if not database.isID(original)
    throw new errors.UnprocessableEntity('Invalid MongoDB id: '+original) 

  query = { 'original': mongoose.Types.ObjectId(original) }
  if version?
    version = version.split('.')
    majorVersion = parseInt(version[0])
    minorVersion = parseInt(version[1])
    query['version.major'] = majorVersion unless _.isNaN(majorVersion)
    query['version.minor'] = minorVersion unless _.isNaN(minorVersion)
  dbq = Model.findOne(query)
  
  dbq.sort({ 'version.major': -1, 'version.minor': -1 })

  # Make sure that permissions and version are fetched, but not sent back if they didn't ask for them.
  projection = parse.getProjectFromReq(req)
  if projection
    extraProjectionProps = []
    extraProjectionProps.push 'permissions' unless projection.permissions
    extraProjectionProps.push 'version' unless projection.version
    projection.permissions = 1
    projection.version = 1
    dbq.select(projection)

  doc = yield dbq.exec()
  throw new errors.NotFound() if not doc
  throw new errors.Forbidden() unless database.hasAccessToDocument(req, doc)
  doc = _.omit doc, extraProjectionProps if extraProjectionProps?
  
  res.status(200).send(doc.toObject())


exports.versions = (Model, options={}) -> wrap (req, res) ->
  original = req.params.handle
  dbq = Model.find({'original': mongoose.Types.ObjectId(original)})
  dbq.sort({'created': -1})
  dbq.limit(parse.getLimitFromReq(req))
  dbq.skip(parse.getSkipFromReq(req))
  dbq.select(parse.getProjectFromReq(req) or 'slug name version commitMessage created creator permissions')
  
  results = yield dbq.exec()
  res.status(200).send(results)
