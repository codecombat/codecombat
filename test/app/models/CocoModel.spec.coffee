CocoModel = require 'models/CocoModel'

class BlandClass extends CocoModel
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
  
describe 'CocoModel', ->
  describe 'save', ->
    
    it 'saves to db/<urlRoot>', ->
      b = new BlandClass({})
      res = b.save()
      request = jasmine.Ajax.requests.mostRecent()
      expect(res).toBeDefined()
      expect(request.url).toBe(b.urlRoot)
      expect(request.method).toBe('POST')
      
    it 'does not save if the data is invalid based on the schema', ->
      b = new BlandClass({number: 'NaN'})
      res = b.save()
      expect(res).toBe(false)
      request = jasmine.Ajax.requests.mostRecent()
      expect(request).toBeUndefined()
      
    it 'uses PUT when _id is included', ->
      b = new BlandClass({_id: 'test'})
      b.save()
      request = jasmine.Ajax.requests.mostRecent()
      expect(request.method).toBe('PUT')

  describe 'patch', ->
    it 'PATCHes only properties that have changed', ->
      b = new BlandClass({_id: 'test', number:1})
      b.loaded = true
      b.set('string', 'string')
      b.patch()
      request = jasmine.Ajax.requests.mostRecent()
      params = JSON.parse request.params
      expect(params.string).toBeDefined()
      expect(params.number).toBeUndefined()
      
    it 'collates all changes made over several sets', ->
      b = new BlandClass({_id: 'test', number:1})
      b.loaded = true
      b.set('string', 'string')
      b.set('object', {4:5})
      b.patch()
      request = jasmine.Ajax.requests.mostRecent()
      params = JSON.parse request.params
      expect(params.string).toBeDefined()
      expect(params.object).toBeDefined()
      expect(params.number).toBeUndefined()

    it 'does not include data from previous patches', ->
      b = new BlandClass({_id: 'test', number:1})
      b.loaded = true
      b.set('object', {1:2})
      b.patch()
      request = jasmine.Ajax.requests.mostRecent()
      attrs = JSON.stringify(b.attributes) # server responds with all
      request.response({status: 200, responseText: attrs})
      
      b.set('number', 3)
      b.patch()
      request = jasmine.Ajax.requests.mostRecent()
      params = JSON.parse request.params
      expect(params.object).toBeUndefined()
      
    it 'does nothing when there\'s nothing to patch', ->
      b = new BlandClass({_id: 'test', number:1})
      b.loaded = true
      b.set('number', 1)
      b.patch()
      request = jasmine.Ajax.requests.mostRecent()
      expect(request).toBeUndefined()
