Patch = require('./Patch')
User = require '../users/User'
Handler = require('../commons/Handler')
schema = require '../../app/schemas/models/patch'
{handlers} = require '../commons/mapping'
mongoose = require('mongoose')
log = require 'winston'
sendwithus = require '../sendwithus'

PatchHandler = class PatchHandler extends Handler
  modelClass: Patch
  editableProperties: []
  postEditableProperties: ['delta', 'target', 'commitMessage']
  jsonSchema: require '../../app/schemas/models/patch'

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

  onPostSuccess: (req, doc) ->
    log.error "Error sending patch created: could not find the loaded target on the patch object." unless doc.targetLoaded
    return unless doc.targetLoaded
    watchers = doc.targetLoaded.get('watchers') or []
    watchers = (w for w in watchers when not w.equals(req.user.get('_id')))
    return unless watchers?.length
    User.find({_id:{$in:watchers}}).select({email:1, name:1}).exec (err, watchers) =>
      for watcher in watchers
        @sendPatchCreatedEmail req.user, watcher, doc, doc.targetLoaded, req.body.editPath
    
  sendPatchCreatedEmail: (patchCreator, watcher, patch, target, editPath) ->
#    return if watcher._id is patchCreator._id
    context =
      email_id: sendwithus.templates.patch_created
      recipient:
        address: watcher.get('email')
        name: watcher.get('name')
      email_data:
        doc_name: target.get('name') or '???'
        submitter_name: patchCreator.get('name') or '???'
        doc_link: "http://codecombat.com#{editPath}"
        commit_message: patch.get('commitMessage')
    sendwithus.api.send context, (err, result) ->

module.exports = new PatchHandler()
