Patch = require('./Patch')
Handler = require('../commons/Handler')
schema = require './patch_schema'
{handlers} = require '../commons/mapping'
mongoose = require('mongoose')

PatchHandler = class PatchHandler extends Handler
  modelClass: Patch
  editableProperties: []
  postEditableProperties: ['delta', 'target', 'commitMessage']
  jsonSchema: require './patch_schema'

  makeNewInstance: (req) ->
    patch = super(req)
    patch.set 'creator', req.user._id
    patch.set 'created', new Date().toISOString()
    patch.set 'status', 'pending'
    patch

  getByRelationship: (req, res, args...) ->
    return @setStatus(req, res, args[0]) if req.route.method is 'put' and args[1] is 'status'
    super(arguments...)
    
  setStatus: (req, res, id) ->
    newStatus = req.body.status
    unless newStatus in ['rejected', 'accepted', 'withdrawn']
      return @sendBadInputError(res, "Status must be 'rejected', 'accepted', or 'withdrawn'")
      
    @getDocumentForIdOrSlug id, (err, patch) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless patch?
      targetInfo = patch.get('target')
      targetHandler = require('../' + handlers[targetInfo.collection])
      targetModel = targetHandler.modelClass

      query = { 'original': targetInfo.original }
      sort = { 'version.major': -1, 'version.minor': -1 }
      targetModel.findOne(query).sort(sort).exec (err, target) =>
        return @sendDatabaseError(res, err) if err
        return @sendNotFoundError(res) unless target?
        return @sendUnauthorizedError(res) unless targetHandler.hasAccessToDocument(req, target, 'get')

        if newStatus in ['rejected', 'accepted']
          return @sendUnauthorizedError(res) unless targetHandler.hasAccessToDocument(req, target, 'put')
        
        if newStatus is 'withdrawn'
          return @sendUnauthorizedError(res) unless req.user.get('_id').equals patch.get('creator')
          
        # these require callbacks
        patch.update {$set:{status:newStatus}}, {}, ->
        target.update {$pull:{patches:patch.get('_id')}}, {}, ->
        @sendSuccess(res, null)
    

module.exports = new PatchHandler()
