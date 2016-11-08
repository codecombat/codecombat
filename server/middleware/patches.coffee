utils = require '../lib/utils'
errors = require '../commons/errors'
wrap = require 'co-express'
database = require '../commons/database'
parse = require '../commons/parse'
{ postPatch } = require './patchable'
mongoose = require 'mongoose'
Patch = require '../models/Patch'
User = require '../models/User'

# TODO: Standardize model names so that this map is unnecessary
collectionNameMap = {
  'achievement': 'Achievement'
  'level_component': 'level.component'
  'level_system': 'level.system'
  'thang_type': 'thang.type'
}

module.exports.post = wrap (req, res) ->
  # Based on body, figure out what collection and document this patch is for
  if not req.body.target?.collection
    throw new errors.UnprocessableEntity('target.collection not provided')
  collection = req.body.target?.collection
  modelName = collectionNameMap[collection] or collection
  try
    Model = mongoose.model(modelName)
  catch e
    if e.name is 'MissingSchemaError'
      throw new errors.NotFound("#{collection} is not a known model")
    else
      throw e
  if not Model.schema.is_patchable
    throw new errors.UnprocessableEntity("#{collection} is not patchable")
    
  # pass to logic shared with "POST /db/:collection/:handle/patch"
  yield postPatch(Model, collection)(req, res)


# Allow patch submitters to withdraw their patches, or admins/artisans to accept/reject others' patches
module.exports.setStatus = wrap (req, res) ->
  
  newStatus = req.body.status or req.body
  unless newStatus in ['rejected', 'accepted', 'withdrawn']
    throw new errors.UnprocessableEntity('Status must be "rejected", "accepted", or "withdrawn"')

  patch = yield database.getDocFromHandle(req, Patch)
  if not patch
    throw new errors.NotFound('Could not find patch')
    
  # Find the target of the patch
  collection = patch.get('target.collection')
  modelName = collectionNameMap[collection] or collection
  Model = mongoose.model(modelName)
  original = patch.get('target.original')
  query = { $or: [{original}, {'_id': mongoose.Types.ObjectId(original)}] }
  sort = { 'version.major': -1, 'version.minor': -1 }
  target = yield Model.findOne(query).sort(sort)
  if not target
    throw new errors.NotFound('Could not find patch target')

  # Enforce permissions
  if newStatus in ['rejected', 'accepted']
    unless req.user.hasPermission('artisan') or target.hasPermissionsForMethod?(req.user, 'put')
      throw new errors.Forbidden('You do not have access to or own the target document.')

  if newStatus is 'withdrawn'
    unless req.user._id.equals patch.get('creator')
      throw new errors.Forbidden('Only the patch creator can withdraw their patch.')

  patch.set 'status', newStatus

  # Only increment statistics upon very first accept
  if patch.isNewlyAccepted()
    acceptor = req.user.id
    patch.set { acceptor }
    yield User.incrementStat acceptor, 'stats.patchesAccepted'

  yield patch.save()
  target.update {$pull: {patches:patch.get('_id')}}, {}, _.noop
  res.send(patch.toObject({req}))
