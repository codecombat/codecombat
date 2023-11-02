SuperModel = require 'models/SuperModel'
User = require 'models/User'
LevelComponents = require 'collections/LevelComponents'
factories = require 'test/app/factories'

describe 'SuperModel', ->
  
  describe '.trackRequest(jqxhr, value)', ->
    it 'takes a jqxhr and tracks its progress', (done) ->
      s = new SuperModel()
      jqxhrA = $.get('/db/a')
      reqA = jasmine.Ajax.requests.mostRecent()
      jqxhrB = $.get('/db/b')
      reqB = jasmine.Ajax.requests.mostRecent()
      s.trackRequest(jqxhrA, 1)
      s.trackRequest(jqxhrB, 3)
      expect(s.progress).toBe(0)
      reqA.respondWith({status: 200, responseText: '[]'})
      _.defer ->
        expect(s.progress).toBe(0.25)
        reqB.respondWith({status: 200, responseText: '[]'})
        _.defer ->
          expect(s.progress).toBe(1)
          done()
  
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
      c = new LevelComponents()
      s.loadModel(c)
      request = jasmine.Ajax.requests.mostRecent()
      expect(request).toBeDefined()

    xdescribe 'timeout handling', ->
      beforeEach ->
        jasmine.clock().install()
      afterEach ->
        jasmine.clock().uninstall()

      it 'automatically retries stalled requests', ->
        s = new SuperModel()
        m = new User({_id: '12345'})
        s.loadModel(m)
        timeUntilRetry = 5000

        # Retry request 5 times
        for timesTried in [1..5]
          expect(s.failed).toBeFalsy()
          expect(s.resources[1].loadsAttempted).toBe(timesTried)
          expect(jasmine.Ajax.requests.all().length).toBe(timesTried)
          jasmine.clock().tick(timeUntilRetry)
          timeUntilRetry *= 1.5

        # And then stop retrying
        expect(s.resources[1].loadsAttempted).toBe(5)
        expect(jasmine.Ajax.requests.all().length).toBe(5)
        expect(s.failed).toBe(true)

      it 'stops retrying once the model loads', (done) ->
        s = new SuperModel()
        m = new User({_id: '12345'})
        s.loadModel(m)
        timeUntilRetry = 5000
        # Retry request 2 times
        for timesTried in [1..2]
          expect(s.failed).toBeFalsy()
          expect(s.resources[1].loadsAttempted).toBe(timesTried)
          expect(jasmine.Ajax.requests.all().length).toBe(timesTried)
          jasmine.clock().tick(timeUntilRetry)
          timeUntilRetry *= 1.5

        # Respond to the third reqest
        expect(s.finished()).toBeFalsy()
        expect(s.failed).toBeFalsy()
        request = jasmine.Ajax.requests.mostRecent()
        request.respondWith({status: 200, responseText: JSON.stringify(factories.makeUser({ _id: '12345' }).attributes)})

        _.defer ->
          expect(s.finished()).toBe(true)
          expect(s.failed).toBeFalsy()

          # It shouldn't send any more requests after loading
          expect(s.resources[1].loadsAttempted).toBe(3)
          expect(jasmine.Ajax.requests.all().length).toBe(3)
          jasmine.clock().tick(60000)
          expect(s.resources[1].loadsAttempted).toBe(3)
          expect(jasmine.Ajax.requests.all().length).toBe(3)
          done()

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

      c1 = new LevelComponents()
      c1.url = '/db/level.component?v=1'
      s.loadCollection(c1, 'components')

      c2 = new LevelComponents()
      c2.url = '/db/level.component?v=2'
      s.loadCollection(c2, 'components')

      request = jasmine.Ajax.requests.sendResponses({
        '/db/level.component?v=1': [{"_id":"id","name":"Something"}]
        '/db/level.component?v=2': [{"_id":"id","description":"This is something"}]
      })

      expect(s.models['/db/level.component/id'].get('name')).toBe('Something')
      expect(s.models['/db/level.component/id'].get('description')).toBe('This is something')
