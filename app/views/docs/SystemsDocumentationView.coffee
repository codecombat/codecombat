CocoView = require 'views/kinds/CocoView'
template = require 'templates/docs/systems-documentation-view'
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

  constructor: (options) ->
    super(options)
    @systemDocs = new SystemDocsCollection()
    @supermodel.loadCollection @systemDocs, 'systems'

  getRenderData: ->
    c = super()
    c.systems = @systemDocs.models
    c.marked = marked
    c.codeLanguage = me.get('aceConfig')?.language ? 'javascript'
    c

  onToggleAllCode: (e) ->
    @collapsed = not @collapsed
    @$el.find('.collapse').collapse(if @collapsed then 'hide' else 'show')
    @$el.find('#toggle-all-system-code').toggleClass 'active', not @collapsed
