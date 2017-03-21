mongoose = require('mongoose')
deltas = require '../../app/core/deltas'
log = require 'winston'
{handlers} = require '../commons/mapping'
config = require '../../server_config'

PatchSchema = new mongoose.Schema({status: String}, {strict: false,read:config.mongo.readpref})
PatchSchema.index({'target.original': 1, 'status': 1}, {name: 'target_status'})

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
  collection = @get('target.collection')

  # Increment patch submitter stats when the patch is "accepted".
  # Does not handle if the patch is accepted multiple times, but that's an edge case.
  if @get('status') is 'accepted'
    User.incrementStat userID, 'stats.patchesContributed' # accepted patches
    if @isTranslationPatch()
      User.incrementStat(userID, 'stats.totalTranslationPatches')
      User.incrementStat(userID, User.statsMapping.translations[collection])
    if @isMiscPatch()
      User.incrementStat(userID, 'stats.totalMiscPatches')
      User.incrementStat(userID, User.statsMapping.misc[collection])

  next()

jsonSchema = require '../../app/schemas/models/patch'
PatchSchema.statics.jsonSchema = jsonSchema

module.exports = mongoose.model('patch', PatchSchema)
