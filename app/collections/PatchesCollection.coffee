PatchModel = require 'models/Patch'
CocoCollection = require 'collections/CocoCollection'

module.exports = class PatchesCollection extends CocoCollection
  model: PatchModel

  initialize: (models, options, forModel, @status='pending') ->
    super(arguments...)
    identifier = if not forModel.get('original') then '_id' else 'original'
    @url = "#{forModel.urlRoot}/#{forModel.get(identifier)}/patches?status=#{@status}"
