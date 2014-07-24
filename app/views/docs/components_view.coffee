#RootView = require 'views/kinds/RootView'
CocoView = require 'views/kinds/RootView'
template = require 'templates/docs/components'
CocoCollection = require 'collections/CocoCollection'
LevelComponent = require 'models/LevelComponent'

class UnnamedView extends CocoView
  className: 'tab-pane'

class ComponentDocsCollection extends CocoCollection
  url: '/db/level.component?project=name,description,dependencies,propertyDocumentation,code'
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
    console.log 'we have the attributes...', (c.attributes for c in @componentDocs.models)
    if (me.get('aceConfig')?.language?) is false
      console.log 'default language javascript'
    else
      console.log 'language is =', me.get('aceConfig').language

    #console.log 'test', @componentDocs.models[99].attributes.propertyDocumentation[1].description['python']
    super()

  getRenderData: ->
    c = super()
    c.components = @componentDocs.models
    c.marked = marked
    if (me.get('aceConfig')?.language?) is false
      c.language = 'javascript'
    else
      c.language = me.get('aceConfig').language
    c
