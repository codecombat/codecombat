utils = require '../lib/utils'
errors = require '../commons/errors'
wrap = require 'co-express'
Promise = require 'bluebird'
Patch = require '../models/Patch'
mongoose = require 'mongoose'

module.exports =
  patches: (options={}) -> wrap (req, res) ->
    dbq = Patch.find()
    dbq.limit(utils.getLimitFromReq(req))
    dbq.skip(utils.getSkipFromReq(req))
    dbq.select(utils.getProjectFromReq(req))

    id = req.params.handle
    if not utils.isID(id)
      throw new errors.UnprocessableEntity('Invalid ID')
      
    query =
      $or: [
        {'target.original': id+''}
        {'target.original': mongoose.Types.ObjectId(id)}
      ]
      status: req.query.status or 'pending'
    
    patches = yield dbq.find(query).sort('-created')
    res.status(200).send(patches)

  joinWatchers: (Model, options={}) -> wrap (req, res) ->
    doc = yield utils.getDocFromHandleAsync(req, Model)
    if not doc
      throw new errors.NotFound('Document not found.')
    if not utils.hasAccessToDocument(req, doc, 'get')
      throw new errors.Forbidden()
    updateResult = yield doc.update({ $addToSet: { watchers: req.user.get('_id') }})
    if updateResult.nModified
      watchers = doc.get('watchers')
      watchers.push(req.user.get('_id'))
      doc.set('watchers', watchers)
    res.status(200).send(doc)
    
  leaveWatchers: (Model, options={}) -> wrap (req, res) ->
    doc = yield utils.getDocFromHandleAsync(req, Model)
    if not doc
      throw new errors.NotFound('Document not found.')
    updateResult = yield doc.update({ $pull: { watchers: req.user.get('_id') }})
    if updateResult.nModified
      watchers = doc.get('watchers')
      watchers = _.filter watchers, (id) -> not id.equals(req.user._id)
      doc.set('watchers', watchers)
    res.status(200).send(doc)