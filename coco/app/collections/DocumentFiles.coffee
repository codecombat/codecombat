CocoCollection = require 'models/CocoCollection'

module.exports = class ModelFiles extends CocoCollection
  constructor: (model) ->
    super()
    url = model.constructor.prototype.urlRoot
    url += "/#{model.get('original') or model.id}/files"
    @url = url 