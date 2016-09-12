utils = require '../lib/utils'
errors = require '../commons/errors'
wrap = require 'co-express'
Promise = require 'bluebird'
Patch = require '../models/Patch'
User = require '../models/User'
mongoose = require 'mongoose'
database = require '../commons/database'
parse = require '../commons/parse'
slack = require '../slack'
{ isJustFillingTranslations } = require '../commons/deltas'
{ updateI18NCoverage } = require '../commons/i18n'
{ initNewVersion, saveNewVersion } = require '../middleware/versions'
{ notifyChangesMadeToDoc } = require '../commons/notify'

module.exports =
  
  patches: (Model, options={}) -> wrap (req, res) ->
    dbq = Patch.find()
    dbq.limit(parse.getLimitFromReq(req))
    dbq.skip(parse.getSkipFromReq(req))
    dbq.select(parse.getProjectFromReq(req))

    doc = yield database.getDocFromHandle(req, Model, {_id: 1})
    if not doc
      throw new errors.NotFound('Patchable document not found')
      
    query =
      $or: [
        {'target.original': doc.id }
        {'target.original': doc._id }
      ]
    if req.query.status
      query.status = req.query.status
    if req.user and req.query.creator is req.user.id
      query.creator = req.user._id
    
    patches = yield dbq.find(query).sort('-created')
    res.status(200).send(patches)

    
  joinWatchers: (Model, options={}) -> wrap (req, res) ->
    doc = yield database.getDocFromHandle(req, Model)
    if not doc
      throw new errors.NotFound('Document not found.')
    if not database.hasAccessToDocument(req, doc, 'get')
      throw new errors.Forbidden()
    updateResult = yield doc.update({ $addToSet: { watchers: req.user.get('_id') }})
    if updateResult.nModified
      watchers = doc.get('watchers')
      watchers.push(req.user.get('_id'))
      doc.set('watchers', watchers)
    res.status(200).send(doc)
    
    
  leaveWatchers: (Model, options={}) -> wrap (req, res) ->
    doc = yield database.getDocFromHandle(req, Model)
    if not doc
      throw new errors.NotFound('Document not found.')
    updateResult = yield doc.update({ $pull: { watchers: req.user.get('_id') }})
    if updateResult.nModified
      watchers = doc.get('watchers')
      watchers = _.filter watchers, (id) -> not id.equals(req.user._id)
      doc.set('watchers', watchers)
    res.status(200).send(doc)

    
  postPatch: _.curry wrap (Model, collectionName, req, res) ->
    # handle either "POST /db/<collection>/:handle/patch" or "POST /db/patch" with target included in body
    if req.params.handle
      target = yield database.getDocFromHandle(req, Model)
    else if req.body.target?.id
      target = yield Model.findById(req.body.target.id)
    if not target
      throw new errors.NotFound('Target not found.')

    # normalize the delta because in tests, changes to patches would sneak in and cause false positives
    # TODO: Figure out a better system. Perhaps submit a series of paths? I18N Edit Views already use them for their rows.
    originalDelta = req.body.delta
    originalTarget = target.toObject()
    # _.cloneDeep can't handle ObjectIds, and be careful with Dates, too.
    newTargetAttrs = _.cloneDeep(target.toObject(), (value) ->
      return value if value instanceof mongoose.Types.ObjectId
      return value if value instanceof Date
      return undefined
    )
    jsondiffpatch.patch(newTargetAttrs, originalDelta)
    normalizedDelta = jsondiffpatch.diff(originalTarget, newTargetAttrs)
    normalizedDelta = _.pick(normalizedDelta, _.keys(originalDelta))

    # decide whether the patch should be auto-accepted, or left 'pending' for an admin or artisan to review
    reasonNotAutoAccepted = undefined
    validation = tv4.validateMultiple(newTargetAttrs, Model.jsonSchema)
    if not validation.valid
      reasonNotAutoAccepted = 'Did not pass json schema.'
    else if not isJustFillingTranslations(normalizedDelta)
      reasonNotAutoAccepted = 'Adding to existing translations.'
      
    else
      # save changes directly to the target, whether versioned or not, and send out notifications
      if Model.schema.uses_coco_versions
        newVersion = database.initDoc(req, Model)
        initNewVersion(newVersion, target)
        newVersionAttrs = newVersion.toObject()
        jsondiffpatch.patch(newVersionAttrs, normalizedDelta)
        newVersion.set(newVersionAttrs)
        newVersion.set('commitMessage', req.body.commitMessage)
        major = target.get('version.major')
        updateI18NCoverage(newVersion)
        yield saveNewVersion(newVersion, major)
        target = newVersion
      else
        target.set(newTargetAttrs)
        updateI18NCoverage(target)
        yield target.save()
      notifyChangesMadeToDoc(req, target)

    # create, validate and save the patch
    if Model.schema.uses_coco_versions
      patchTarget = {
        collection: collectionName
        id: target._id
        original: target._id
        version: _.pick(target.get('version'), 'major', 'minor')
      }
    else
      patchTarget = {
        collection: collectionName
        id: target._id
        original: target._id
      }

    patch = new Patch()
    patch.set({
      delta: normalizedDelta
      commitMessage: req.body.commitMessage
      target: patchTarget
      creator: req.user._id
      status: if reasonNotAutoAccepted then 'pending' else 'accepted'
      created: new Date().toISOString()
      reasonNotAutoAccepted: reasonNotAutoAccepted
    })
    database.validateDoc(patch)

    # add this patch to the denormalized list of patches on the target
    if reasonNotAutoAccepted
      yield target.update({ $addToSet: { patches: patch._id }})

    yield patch.save()
    
    User.incrementStat req.user.id, 'stats.patchesSubmitted'

    res.status(201).send(patch.toObject({req: req}))

    if reasonNotAutoAccepted
      docLink = "https://codecombat.com/editor/#{collectionName}/#{target.id}"
      message = "#{req.user.get('name')} submitted a patch to #{target.get('name')}: #{patch.get('commitMessage')} #{docLink}"
      slack.sendSlackMessage message, ['artisans']
