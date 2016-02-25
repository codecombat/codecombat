CocoModel = require 'models/CocoModel'
utils = require 'core/utils'

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
  describe 'setProjection', ->
    it 'takes an array of properties to project and adds them as a query parameter', ->
      b = new BlandClass({})
      b.setProjection ['number', 'object']
      b.fetch()
      request = jasmine.Ajax.requests.mostRecent()
      expect(decodeURIComponent(request.url).indexOf('project=number,object')).toBeGreaterThan(-1)

    it 'can update its projection', ->
      baseURL = '/db/bland/test?filter-creator=Mojambo&project=number,object&ignore-evil=false'
      unprojectedURL = baseURL.replace /&project=number,object/, ''
      b = new BlandClass({})
      b.setURL baseURL
      expect(b.getURL()).toBe baseURL
      b.setProjection ['number', 'object']
      expect(b.getURL()).toBe baseURL
      b.setProjection ['number']
      expect(b.getURL()).toBe baseURL.replace /,object/, ''
      b.setProjection []
      expect(b.getURL()).toBe unprojectedURL
      b.setProjection null
      expect(b.getURL()).toBe unprojectedURL
      b.setProjection ['object', 'number']
      expect(b.getURL()).toBe unprojectedURL + '&project=object,number'

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
      b = new BlandClass({_id: 'test', number: 1})
      b.loaded = true
      b.set('string', 'string')
      b.patch()
      request = jasmine.Ajax.requests.mostRecent()
      params = JSON.parse request.params
      expect(params.string).toBeDefined()
      expect(params.number).toBeUndefined()

    it 'collates all changes made over several sets', ->
      b = new BlandClass({_id: 'test', number: 1})
      b.loaded = true
      b.set('string', 'string')
      b.set('object', {4: 5})
      b.patch()
      request = jasmine.Ajax.requests.mostRecent()
      params = JSON.parse request.params
      expect(params.string).toBeDefined()
      expect(params.object).toBeDefined()
      expect(params.number).toBeUndefined()

    it 'does not include data from previous patches', ->
      b = new BlandClass({_id: 'test', number: 1})
      b.loaded = true
      b.set('object', {1: 2})
      b.patch()
      request = jasmine.Ajax.requests.mostRecent()
      attrs = JSON.stringify(b.attributes) # server responds with all
      request.respondWith({status: 200, responseText: attrs})

      b.set('number', 3)
      b.patch()
      request = jasmine.Ajax.requests.mostRecent()
      params = JSON.parse request.params
      expect(params.object).toBeUndefined()

    it 'does nothing when there\'s nothing to patch', ->
      b = new BlandClass({_id: 'test', number: 1})
      b.loaded = true
      b.set('number', 1)
      b.patch()
      request = jasmine.Ajax.requests.mostRecent()
      expect(request).toBeUndefined()

  xdescribe 'Achievement polling', ->
    # TODO: Figure out how to do debounce in tests so that this test doesn't need to use keepDoingUntil

    it 'achievements are polled upon saving a model', (done) ->
      #spyOn(CocoModel, 'pollAchievements')
      Backbone.Mediator.subscribe 'achievements:new', (collection) ->
        Backbone.Mediator.unsubscribe 'achievements:new'
        expect(collection.constructor.name).toBe('NewAchievementCollection')
        done()

      b = new BlandClass({})
      res = b.save()
      request = jasmine.Ajax.requests.mostRecent()
      request.respondWith(status: 200, responseText: '{}')

      collection = []
      model =
        _id: "5390f7637b4d6f2a074a7bb4"
        achievement: "537ce4855c91b8d1dda7fda8"
      collection.push model

      utils.keepDoingUntil (ready) ->
        request = jasmine.Ajax.requests.mostRecent()
        achievementURLMatch = (/.*achievements\?notified=false$/).exec request.url
        if achievementURLMatch
          ready true
        else return ready false

        request.respondWith {status: 200, responseText: JSON.stringify collection}

        utils.keepDoingUntil (ready) ->
          request = jasmine.Ajax.requests.mostRecent()
          userURLMatch = (/^\/db\/user\/[a-zA-Z0-9]*$/).exec request.url
          if userURLMatch
            ready true
          else return ready false

          request.respondWith {status:200, responseText: JSON.stringify me}

  describe 'updateI18NCoverage', ->
    class FlexibleClass extends CocoModel
      @className: 'Flexible'
      @schema: {}

    it 'only includes languages for which all objects include a translation', ->
      m = new FlexibleClass({
        i18n: { es: {}, fr: {} }
        prop1: 1
        prop2: 'string'
        prop3: true
        innerObject: {
          i18n: { es: {}, de: {}, fr: {} }
          prop4: [
            {
              i18n: { es: {} }
            }
          ]
        }
      })

      m.updateI18NCoverage()
      expect(JSON.stringify(m.get('i18nCoverage'))).toBe('["es"]')
