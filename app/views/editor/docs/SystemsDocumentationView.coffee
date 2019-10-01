require('app/styles/docs/systems-documentation-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/editor/docs/systems-documentation-view'
CocoCollection = require 'collections/CocoCollection'
LevelSystem = require 'models/LevelSystem'

class SystemDocsCollection extends CocoCollection
  url: '/db/level.system?project=name,description,code'
  model: LevelSystem
  comparator: 'name'

module.exports = class SystemsDocumentationView extends CocoView
  id: 'systems-documentation-view'
  template: template
  className: 'tab-pane'
  collapsed: true

  events:
    'click #toggle-all-system-code': 'onToggleAllCode'

  subscriptions:
    'editor:view-switched': 'onViewSwitched'

  constructor: (options) ->
    super(options)
    @systemDocs = new SystemDocsCollection()
    @loadDocs() unless options.lazy

  loadDocs: ->
    return if @loadingDocs
    @supermodel.loadCollection @systemDocs, 'systems'
    @loadingDocs = true
    @render()

  getRenderData: ->
    c = super()
    c.systems = @systemDocs.models
    c.marked = marked
    c.codeLanguage = me.get('aceConfig')?.language ? 'python'
    c

  onToggleAllCode: (e) ->
    @collapsed = not @collapsed
    @$el.find('.collapse').collapse(if @collapsed then 'hide' else 'show')
    @$el.find('#toggle-all-system-code').toggleClass 'active', not @collapsed

  onViewSwitched: (e) ->
    return unless e.targetURL is '#editor-level-documentation'
    @loadDocs()
