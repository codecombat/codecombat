require('app/styles/editor/component/add-thang-components-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/editor/component/add-thang-components-modal'
CocoCollection = require 'collections/CocoCollection'
LevelComponent = require 'models/LevelComponent'

module.exports = class UnnamedView extends ModalView
  id: 'add-thang-components-modal'
  template: template
  plain: true
  modalWidthPercent: 80
  
  events:
    'click .footer button': 'onDonePressed'
  
  initialize: (options) ->
    super()
    @skipOriginals = options.skipOriginals or []
    @components = new CocoCollection([], model: LevelComponent)
    @components.url = "/db/level.component?term=&project=name,system,original,version,description"
    @supermodel.loadCollection(@components, 'components')
    
  getRenderData: ->
    c = super()
    c.components = (comp for comp in @components.models when not (comp.get('original') in @skipOriginals))
    c.components = _.groupBy(c.components, (comp) -> comp.get('system'))
    c.nameLists = {}
    for system, componentList of c.components
      c.components[system] = _.sortBy(componentList, (comp) -> comp.get('name'))
      c.nameLists[system] = (comp.get('name') for comp in c.components[system]).join(', ')
    c.systems = _.keys(c.components)
    c.systems.sort()
    c
    
  getSelectedComponents: ->
    selected = @$el.find('input[type="checkbox"]:checked')
    vals = ($(el).val() for el in selected)
    components = (c for c in @components.models when c.id in vals)
    return components
#    sparseComponents = ({original: c.get('original'), majorVersion: c.get('version').major} for c in components)
#    return sparseComponents