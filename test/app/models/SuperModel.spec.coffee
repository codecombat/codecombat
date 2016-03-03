SuperModel = require 'models/SuperModel'
User = require 'models/User'
ComponentsCollection = require 'collections/ComponentsCollection'

describe 'SuperModel', ->
  describe 'progress (property)', ->
    it 'is finished by default', ->
      s = new SuperModel()
      expect(s.finished()).toBeTruthy()

    it 'is based on resource completion and value', (done) ->
      s = new SuperModel()
      r1 = s.addSomethingResource('???', 2)
      r2 = s.addSomethingResource('???', 3)
      expect(s.progress).toBe(0)
      r1.markLoaded()

      # progress updates are deferred so defer more
      _.defer ->
        expect(s.progress).toBe(0.4)
        r2.markLoaded()
        _.defer ->
          expect(s.progress).toBe(1)
          done()

  describe 'loadModel (function)', ->
    it 'starts loading the model if it isn\'t already loading', ->
      s = new SuperModel()
      m = new User({_id: '12345'})
      s.loadModel(m)
      request = jasmine.Ajax.requests.mostRecent()
      expect(request).toBeDefined()

    it 'also loads collections', ->
      s = new SuperModel()
      c = new ComponentsCollection()
      s.loadModel(c)
      request = jasmine.Ajax.requests.mostRecent()
      expect(request).toBeDefined()

  describe 'events', ->
    it 'triggers "loaded-all" when finished', (done) ->
      s = new SuperModel()
      m = new User({_id: '12345'})
      triggered = false
      s.once 'loaded-all', -> triggered = true
      s.loadModel(m)
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith({status: 200, responseText: '{}'})
      _.defer ->
        expect(triggered).toBe(true)
        done()

  describe 'collection loading', ->
    it 'combines models which are fetched from multiple sources', ->
      s = new SuperModel()

      c1 = new ComponentsCollection()
      c1.url = '/db/level.component?v=1'
      s.loadCollection(c1, 'components')

      c2 = new ComponentsCollection()
      c2.url = '/db/level.component?v=2'
      s.loadCollection(c2, 'components')

      request = jasmine.Ajax.requests.sendResponses({
        '/db/level.component?v=1': [{"_id":"id","name":"Something"}]
        '/db/level.component?v=2': [{"_id":"id","description":"This is something"}]
      })

      expect(s.models['/db/level.component/id'].get('name')).toBe('Something')
      expect(s.models['/db/level.component/id'].get('description')).toBe('This is something')
