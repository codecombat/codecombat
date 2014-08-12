ThangComponentEditView = require('views/editor/component/ThangComponentsEditView')

responses = 
  '/db/level.component/A/version/0': { 
    system: 'System'
    original: 'A'
    majorVersion: 0
    name: 'A'
    configSchema: { type: 'object', properties: { propA: { type: 'number' }, propB: { type: 'string' }} }
    
  }
  '/db/level.component/B/version/0': { 
    system: 'System'
    original: 'B'
    majorVersion: 0
    name: 'B (depends on A)'
    dependencies: [{original:'A', majorVersion: 0}] 
  }
  '/db/level.component/C/version/0': { 
    system: 'System'
    original: 'C'
    majorVersion: 0
    name: 'C (depends on B)'
    dependencies: [{original:'B', majorVersion: 0}]
  }

module.exports = ->
  view = new ThangComponentEditView({
    components: [
      { original: 'A', majorVersion: 0, config: {propA: 1, propB: 'string'} }
      { original: 'B', majorVersion: 0 }
      { original: 'C', majorVersion: 0 }
    ]
  })
  
  view.render()
  jasmine.Ajax.requests.sendResponses(responses)
  view.$el.css('background', 'white')
  
  return view