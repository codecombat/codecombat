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
      s.loadModel(m, 'user')
      request = jasmine.Ajax.requests.mostRecent()
      expect(request).toBeDefined()

    it 'also loads collections', ->
      s = new SuperModel()
      c = new ComponentsCollection()
      s.loadModel(c, 'collection')
      request = jasmine.Ajax.requests.mostRecent()
      expect(request).toBeDefined()

  describe 'events', ->
    it 'triggers "loaded-all" when finished', (done) ->
      s = new SuperModel()
      m = new User({_id: '12345'})
      triggered = false
      s.once 'loaded-all', -> triggered = true
      s.loadModel(m, 'user')
      request = jasmine.Ajax.requests.mostRecent()
      request.response({status: 200, responseText: '{}'})
      _.defer ->
        expect(triggered).toBe(true)
        done()
