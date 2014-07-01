PatchModel = require 'models/Patch'
CocoCollection = require 'collections/CocoCollection'

module.exports = class PatchesCollection extends CocoCollection
  model: PatchModel

  initialize: (models, options, forModel, @status='pending') ->
    super(arguments...)
    @url = "#{forModel.urlRoot}/#{forModel.get('original')}/patches?status=#{@status}"
