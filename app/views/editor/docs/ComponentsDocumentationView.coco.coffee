require('app/styles/docs/components-documentation-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/editor/docs/components-documentation-view'
CocoCollection = require 'collections/CocoCollection'
LevelComponent = require 'models/LevelComponent'

class ComponentDocsCollection extends CocoCollection
  url: '/db/level.component?project=system,name,description,dependencies,propertyDocumentation,code'
  model: LevelComponent
  comparator: 'system'

module.exports = class ComponentsDocumentationView extends CocoView
  id: 'components-documentation-view'
  template: template
  className: 'tab-pane'
  collapsed: true

  events:
    'click #toggle-all-component-code': 'onToggleAllCode'

  subscriptions:
    'editor:view-switched': 'onViewSwitched'

  constructor: (options) ->
    super(options)
    @componentDocs = new ComponentDocsCollection()
    @loadDocs() unless options.lazy

  loadDocs: ->
    return if @loadingDocs
    @supermodel.loadCollection @componentDocs, 'components'
    @loadingDocs = true
    @render()

  getRenderData: ->
    c = super()
    c.components = @componentDocs.models
    c.marked = marked
    c.codeLanguage = me.get('aceConfig')?.language ? 'python'
    c

  onToggleAllCode: (e) ->
    @collapsed = not @collapsed
    @$el.find('.collapse').collapse(if @collapsed then 'hide' else 'show')
    @$el.find('#toggle-all-component-code').toggleClass 'active', not @collapsed

  onViewSwitched: (e) ->
    return unless e.targetURL is '#editor-level-documentation'
    @loadDocs()
