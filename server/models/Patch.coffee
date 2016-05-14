mongoose = require('mongoose')
deltas = require '../../app/core/deltas'
log = require 'winston'
{handlers} = require '../commons/mapping'
config = require '../../server_config'

PatchSchema = new mongoose.Schema({status: String}, {strict: false,read:config.mongo.readpref})

PatchSchema.pre 'save', (next) ->
  return next() unless @isNew # patch can't be altered after creation, so only need to check data once
  target = @get('target')
  targetID = target.id
  Handler = require '../commons/Handler'
  if not Handler.isID(targetID)
    err = new Error('Invalid input.')
    err.response = {message: 'isn\'t a MongoDB id.', property: 'target.id'}
    err.code = 422
    return next(err)

  collection = target.collection
  try
    handler = require('../' + handlers[collection])
  catch err
    console.error 'Couldn\'t find handler for collection:', target.collection, 'from target', target
    err = new Error('Server error.')
    err.response = {message: '', property: 'target.id'}
    err.code = 500
    return next(err)
  handler.getDocumentForIdOrSlug targetID, (err, document) =>
    if err
      err = new Error('Server error.')
      err.response = {message: '', property: 'target.id'}
      err.code = 500
      return next(err)

    if not document
      err = new Error('Target of patch not found.')
      err.response = {message: 'was not found.', property: 'target.id'}
      err.code = 404
      return next(err)

    target.id = document.get('_id')
    if handler.modelClass.schema.uses_coco_versions
      target.original = document.get('original')
      version = document.get('version')
      target.version = _.pick document.get('version'), 'major', 'minor'
      @set('target', target)
    else
      target.original = targetID

    patches = document.get('patches') or []
    patches = _.clone patches
    patches.push @_id
    document.set 'patches', patches, {strict: false}
    @targetLoaded = document
    document.save (err) -> next(err)

PatchSchema.methods.isTranslationPatch = -> # Don't ever fat arrow bind this one
  expanded = deltas.flattenDelta @get('delta')
  _.some expanded, (delta) -> 'i18n' in delta.dataPath

PatchSchema.methods.isMiscPatch = ->
  expanded = deltas.flattenDelta @get('delta')
  _.some expanded, (delta) -> 'i18n' not in delta.dataPath

# Keep track of when a patch is pending and newly approved.
PatchSchema.path('status').set (newVal) ->
  @set 'wasPending', @status is 'pending' and newVal isnt 'pending'
  @set 'newlyAccepted', newVal is 'accepted' and not @get('newlyAccepted') # Only true on the first accept
  newVal

PatchSchema.methods.isNewlyAccepted = -> @get('newlyAccepted')
PatchSchema.methods.wasPending = -> @get 'wasPending'

PatchSchema.pre 'save', (next) ->
  User = require './User'
  userID = @get('creator').toHexString()

  if @get('status') is 'accepted'
    User.incrementStat userID, 'stats.patchesContributed' # accepted patches
  else if @get('status') is 'pending'
    User.incrementStat userID, 'stats.patchesSubmitted'   # submitted patches

  next()

module.exports = mongoose.model('patch', PatchSchema)
