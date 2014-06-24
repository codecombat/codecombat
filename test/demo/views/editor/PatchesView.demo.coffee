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
  model = new BlandModel({_id:'12345', name:'name', original:'original'})
  v = new PatchesView(model)
  v.load()

  # Respond to request for pending patches.
  r = jasmine.Ajax.requests.mostRecent()
  patches = [
    {
      delta: null
      commitMessage: 'Demo message'
      creator: '12345'
      created: "2014-01-01T12:00:00.000Z"
      status: 'pending'
    }
  ]
  r.response({ status:200, responseText: JSON.stringify patches })
  
  # Respond to request for user ids -> names
  r = jasmine.Ajax.requests.mostRecent()
  names = { '12345': { name: 'Patchman' } }
  r.response({ status:200, responseText: JSON.stringify names })
  
  v.render()
  v
  
