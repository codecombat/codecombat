CocoCollection = require 'collections/CocoCollection'
File = require 'models/File'

module.exports = class ModelFiles extends CocoCollection
  model: File

  constructor: (model) ->
    super()
    url = model.constructor.prototype.urlRoot
    url += "/#{model.get('original') or model.id}/files"
    @url = url
