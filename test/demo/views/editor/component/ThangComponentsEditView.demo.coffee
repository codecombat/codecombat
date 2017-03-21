ThangComponentEditView = require('views/editor/component/ThangComponentsEditView')
ThangType = require 'models/ThangType'

responses = 
  '/db/level.component/A/version/0': { 
    system: 'System'
    original: 'A'
    version: { major: 0, minor: 0 }
    name: 'A'
    configSchema: { 
      type: 'object' 
      properties: { 
        propA: { type: 'number' }
        propB: { type: 'string' }
      } 
    }
  }
  '/db/level.component/B/version/0': { 
    system: 'System'
    original: 'B'
    version: { major: 0, minor: 0 }
    name: 'B (depends on A)'
    dependencies: [{original:'A', majorVersion: 0}] 
  }
  '/db/level.component/C/version/0': { 
    system: 'System'
    original: 'C'
    version: { major: 0, minor: 0 }
    name: 'C (depends on B)'
    dependencies: [{original:'B', majorVersion: 0}]
    configSchema: {
      type: 'object'
      default: { propC: 'Default property from component config' }
    }
  }
  '/db/level.component/D/version/0': {
    system: 'System'
    original: 'D'
    version: { major: 0, minor: 0 }
    name: 'D (comes from ThangType components)'
  }
  '/db/thang.type': []

module.exports = ->
  view = new ThangComponentEditView({
    components: [
      { original: 'B', majorVersion: 0 }
      { original: 'C', majorVersion: 0 }
      { original: 'A', majorVersion: 0, config: {propA: 1, propB: 'string'} }
    ]
    thangType: new ThangType({
      components: [
        { original: 'A', majorVersion: 0, config: {propD: 'Default property from thang type component.'} }
        { original: 'D', majorVersion: 0, config: {prop1: 'one', prop2: 'two'} }
      ]
    })
  })
  
  view.render()
  jasmine.Ajax.requests.sendResponses(responses)
  view.$el.css('background', 'white')
  
  return view