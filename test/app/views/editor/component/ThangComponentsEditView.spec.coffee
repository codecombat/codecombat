ThangComponentEditView = require('views/editor/component/ThangComponentsEditView')
SuperModel = require('models/SuperModel')
LevelComponent = require('models/LevelComponent')

responses =
  '/db/level.component/B/version/0': {
    system: 'System'
    original: 'B'
    majorVersion: 0
    name: 'B (depends on A)'
    dependencies: [{original:'A', majorVersion: 0}]
  }
  '/db/level.component/A/version/0': {
    system: 'System'
    original: 'A'
    majorVersion: 0
    name: 'A'
    configSchema: { type: 'object', properties: { propA: { type: 'number' }, propB: { type: 'string' }} }
  }
  
componentC = new LevelComponent({
  system: 'System'
  original: 'C'
  majorVersion: 0
  name: 'C (depends on B)'
  dependencies: [{original:'B', majorVersion: 0}]
})
componentC.loaded = true

describe 'ThangComponentsEditView', ->
  view = null
  
  beforeEach (done) ->
    supermodel = new SuperModel()
    supermodel.registerModel(componentC)
    view = new ThangComponentEditView({ components: [], supermodel: supermodel })
    jasmine.Ajax.requests.sendResponses { '/db/thang.type': [] }
    _.delay ->
      view.render()
      view.componentsTreema.set('/', [ { original: 'C', majorVersion: 0 }])
      spyOn(window, 'noty')
      done()

  it 'loads dependencies when you add a component with the left side treema', ->
    success = jasmine.Ajax.requests.sendResponses(responses)
    expect(success).toBeTruthy()
    expect(_.size(view.subviews)).toBe(3)
    
  it 'adds dependencies to its components list', ->
    jasmine.Ajax.requests.sendResponses(responses)
    componentOriginals = (c.original for c in view.components)
    expect('A' in componentOriginals).toBeTruthy()
    expect('B' in componentOriginals).toBeTruthy()
    expect('C' in componentOriginals).toBeTruthy()
    
  it 'removes components that are dependent on a removed component', ->
    jasmine.Ajax.requests.sendResponses(responses)
    view.components = (c for c in view.components when c.original isnt 'A')
    view.onComponentsChanged()
    expect(view.components.length).toBe(0)
    expect(_.size(view.subviews)).toBe(0)