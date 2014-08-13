#RootView = require 'views/kinds/RootView'
CocoView = require 'views/kinds/CocoView'
template = require 'templates/docs/components'
CocoCollection = require 'collections/CocoCollection'
LevelComponent = require 'models/LevelComponent'

class ComponentDocsCollection extends CocoCollection
  url: '/db/level.component?project=name,description,dependencies,propertyDocumentation,code'
  model: LevelComponent

module.exports = class ComponentDocumentationView extends CocoView
  id: 'docs-components-view'
  template: template
  className: 'tab-pane'

  constructor: (options) ->
    super(options)
    @componentDocs = new ComponentDocsCollection()
    @supermodel.loadCollection @componentDocs, 'components'

  getRenderData: ->
    c = super()
    c.components = @componentDocs.models
    c.marked = marked
    c.codeLanguage = me.get('aceConfig')?.language ? 'javascript'
    c
