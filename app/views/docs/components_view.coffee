RootView = require 'views/kinds/RootView'
template = require 'templates/docs/components'
CocoCollection = require 'collections/CocoCollection'
LevelComponent = require 'models/LevelComponent'

class ComponentDocsCollection extends CocoCollection
  url: '/db/level.component?project=name,description,dependencies,propertyDocumentation'
  model: LevelComponent

module.exports = class UnnamedView extends RootView
  id: 'docs-components-view'
  template: template

  constructor: (options) ->
    super(options)
    @componentDocs = new ComponentDocsCollection()
    @supermodel.loadCollection @componentDocs, 'components'
    
  onLoaded: ->
    console.log 'we have the components...', (c.get('name') for c in @componentDocs.models)
    super()

  getRenderData: ->
    c = super()
    c.components = @componentDocs.models
    c
