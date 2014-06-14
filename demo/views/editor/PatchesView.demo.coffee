PatchesView = require 'views/editor/patches_view'
CocoModel = require 'models/CocoModel'

class BlandModel extends CocoModel
  @className: 'Bland'
  @schema: {
    type: 'object'
    additionalProperties: false
    properties:
      number: {type: 'number'}
      object: {type: 'object'}
      string: {type: 'string'}
      _id: {type: 'string'}
  }
  urlRoot: '/db/bland'


module.exports = ->
  model = new BlandModel({_id:'12345'})
  new PatchesView(model)
  
