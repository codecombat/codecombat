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
  v = new PatchesView(model)
  v.load()

  # doesn't quite work yet. Intercepts a mixpanel request instead
  r = jasmine.Ajax.requests.mostRecent()
  r.send({statusCode:200, responseText:"[]"}) 
  v.render()
  v
  
