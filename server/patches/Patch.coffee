mongoose = require('mongoose')
{handlers} = require '../commons/mapping'

PatchSchema = new mongoose.Schema({}, {strict: false})

PatchSchema.pre 'save', (next) ->
  return next() unless @isNew # patch can't be altered after creation, so only need to check data once
  target = @get('target')
  targetID = target.id
  Handler = require '../commons/Handler'
  if not Handler.isID(targetID)
    err = new Error('Invalid input.')
    err.response = {message:"isn't a MongoDB id.", property:'target.id'}
    err.code = 422
    return next(err)
  
  collection = target.collection
  handler = require('../' + handlers[collection])
  handler.getDocumentForIdOrSlug targetID, (err, document) =>
    if err
      err = new Error('Server error.')
      err.response = {message:'', property:'target.id'}
      err.code = 500
      return next(err)

    if not document
      err = new Error('Target of patch not found.')
      err.response = {message:'was not found.', property:'target.id'}
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

module.exports = mongoose.model('patch', PatchSchema)
