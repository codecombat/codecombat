Patch = require './../models/Patch'
User = require '../models/User'
Handler = require '../commons/Handler'
schema = require '../../app/schemas/models/patch'
{handlers} = require '../commons/mapping'
mongoose = require 'mongoose'
log = require 'winston'
sendwithus = require '../sendwithus'
slack = require '../slack'

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

  get: (req, res) ->
    if req.query.view in ['pending']
      query = status: 'pending'
      q = Patch.find(query)
      q.exec (err, documents) =>
        return @sendDatabaseError(res, err) if err
        documents = (@formatEntity(req, doc) for doc in documents)
        @sendSuccess(res, documents)
    else
      super(arguments...)

  setStatus: (req, res, id) ->
    newStatus = req.body.status
    unless newStatus in ['rejected', 'accepted', 'withdrawn']
      return @sendBadInputError(res, 'Status must be "rejected", "accepted", or "withdrawn"')

    @getDocumentForIdOrSlug id, (err, patch) =>
      return @sendDatabaseError(res, err) if err
      return @sendNotFoundError(res) unless patch?
      targetInfo = patch.get('target')
      targetHandler = require('../' + handlers[targetInfo.collection])
      targetModel = targetHandler.modelClass

      query = { $or: [{'original': targetInfo.original}, {'_id': mongoose.Types.ObjectId(targetInfo.original)}] }
      sort = { 'version.major': -1, 'version.minor': -1 }
      targetModel.findOne(query).sort(sort).exec (err, target) =>
        return @sendDatabaseError(res, err) if err
        return @sendNotFoundError(res) unless target?
        return @sendForbiddenError(res) unless targetHandler.hasAccessToDocument(req, target, 'get')

        if newStatus in ['rejected', 'accepted']
          return @sendForbiddenError(res) unless targetHandler.hasAccessToDocument(req, target, 'put')

        if newStatus is 'withdrawn'
          return @sendForbiddenError(res) unless req.user.get('_id').equals patch.get('creator')

        patch.set 'status', newStatus

        # Only increment statistics upon very first accept
        if patch.isNewlyAccepted()
          patch.set 'acceptor', req.user.get('id')
          acceptor = req.user.get 'id'
          submitter = patch.get 'creator'
          User.incrementStat acceptor, 'stats.patchesAccepted'
          # TODO maybe merge these increments together
          if patch.isTranslationPatch()
            User.incrementStat submitter, 'stats.totalTranslationPatches'
            User.incrementStat submitter, User.statsMapping.translations[targetModel.modelName]
          if patch.isMiscPatch()
            User.incrementStat submitter, 'stats.totalMiscPatches'
            User.incrementStat submitter, User.statsMapping.misc[targetModel.modelName]


        # these require callbacks
        patch.save (err) =>
          log.error err if err?
          target.update {$pull:{patches:patch.get('_id')}}, {}, ->
          @sendSuccess(res, null)

  onPostSuccess: (req, doc) ->
    log.error 'Error sending patch created: could not find the loaded target on the patch object.' unless doc.targetLoaded
    return unless doc.targetLoaded
    docLink = "http://codecombat.com#{req.headers['x-current-path']}"
    @sendPatchCreatedSlackMessage creator: req.user, patch: doc, target: doc.targetLoaded, docLink: docLink
    watchers = doc.targetLoaded.get('watchers') or []
    # Don't send these emails to the person who submitted the patch, or to Nick, George, or Scott.
    watchers = (w for w in watchers when not w.equals(req.user.get('_id')) and not (w + '' in ['512ef4805a67a8c507000001', '5162fab9c92b4c751e000274', '51538fdb812dd9af02000001']))
    return unless watchers?.length
    User.find({_id: {$in: watchers}}).select({email: 1, name: 1}).exec (err, watchers) =>
      for watcher in watchers
        @sendPatchCreatedEmail req.user, watcher, doc, doc.targetLoaded, docLink

  sendPatchCreatedEmail: (patchCreator, watcher, patch, target, docLink) ->
#    return if watcher._id is patchCreator._id
    context =
      email_id: sendwithus.templates.patch_created
      recipient:
        address: watcher.get('email')
        name: watcher.get('name')
      email_data:
        doc_name: target.get('name') or '???'
        submitter_name: patchCreator.get('name') or '???'
        doc_link: docLink
        commit_message: patch.get('commitMessage')
    sendwithus.api.send context, (err, result) ->

  sendPatchCreatedSlackMessage: (options) ->
    message = "#{options.creator.get('name')} submitted a patch to #{options.target.get('name')}: #{options.patch.get('commitMessage')} #{options.docLink}"
    slack.sendSlackMessage message, ['artisans']

module.exports = new PatchHandler()
