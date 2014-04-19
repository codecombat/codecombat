View = require 'views/kinds/CocoView'
template = require 'templates/editor/level/components_tab'
LevelComponent = require 'models/LevelComponent'
LevelComponentEditView = require './component/edit'
LevelComponentNewView = require './component/new'

class LevelComponentCollection extends Backbone.Collection
  url: '/db/level.component'
  model: LevelComponent

module.exports = class ComponentsTabView extends View
  id: "editor-level-components-tab-view"
  template: template
  className: 'tab-pane'

  subscriptions:
    'level-thangs-changed': 'onLevelThangsChanged'
    'edit-level-component': 'editLevelComponent'
    'level-component-edited': 'onLevelComponentEdited'
    'level-component-editing-ended': 'onLevelComponentEditingEnded'

  events:
    'click #create-new-component-button': 'createNewLevelComponent'
    'click #create-new-component-button-no-select': 'createNewLevelComponent'

  onLevelThangsChanged: (e) ->
    thangsData = e.thangsData
    presentComponents = {}
    for thang in thangsData
      for component in thang.components
        haveThisComponent = (presentComponents[component.original + '.' + (component.majorVersion ? 0)] ?= [])
        haveThisComponent.push thang.id if haveThisComponent.length < 100  # for performance when adding many Thangs
    return if _.isEqual presentComponents, @presentComponents
    @presentComponents = presentComponents

    componentModels = @supermodel.getModels LevelComponent
    componentModelMap = {}
    componentModelMap[comp.get('original')] = comp for comp in componentModels    
    components = ({original: key.split('.')[0], majorVersion: parseInt(key.split('.')[1], 10), thangs: value, count: value.length} for key, value of @presentComponents)
    treemaData = _.sortBy components, (comp) ->
      comp = componentModelMap[comp.original]
      res = [comp.get('system'), comp.get('name')]
      return res
      
    treemaOptions =
      supermodel: @supermodel
      schema: {type: 'array', items: {type: 'object', format: 'level-component'}}
      data: treemaData
      callbacks:
        select: @onTreemaComponentSelected
      readOnly: true
      nodeClasses: {'level-component': LevelComponentNode}
    @componentsTreema = @$el.find('#components-treema').treema treemaOptions
    @componentsTreema.build()
    @componentsTreema.open()

  onTreemaComponentSelected: (e, selected) =>
    selected = if selected.length > 1 then selected[0].getLastSelectedTreema() else selected[0]
    unless selected
      @removeSubView @levelComponentEditView
      @levelComponentEditView = null
      return

    @editLevelComponent original: selected.data.original, majorVersion: selected.data.majorVersion

  createNewLevelComponent: (e) ->
    levelComponentNewView = new LevelComponentNewView supermodel: @supermodel
    @openModalView levelComponentNewView
    Backbone.Mediator.publish 'level:view-switched', e

  editLevelComponent: (e) ->
    @levelComponentEditView = @insertSubView new LevelComponentEditView(original: e.original, majorVersion: e.majorVersion, supermodel: @supermodel)

  onLevelComponentEdited: (e) ->
    Backbone.Mediator.publish 'level-components-changed', {}

  onLevelComponentEditingEnded: (e) ->
    @removeSubView @levelComponentEditView
    @levelComponentEditView = null

class LevelComponentNode extends TreemaObjectNode
  valueClass: 'treema-level-component'
  collection: false
  buildValueForDisplay: (valEl) ->
    count = if @data.count is 1 then @data.thangs[0] else ((if @data.count >= 100 then "100+" else @data.count) + " Thangs")
    if @data.original.match ":"
      name = "Old: " + @data.original.replace('systems/', '')
    else
      comp = _.find @settings.supermodel.getModels(LevelComponent), (m) =>
        m.get('original') is @data.original and m.get('version').major is @data.majorVersion
      name = "#{comp.get('system')}.#{comp.get('name')} v#{comp.get('version').major}"
    @buildValueForDisplaySimply valEl, "#{name} (#{count})"

  onEnterPressed: ->
    Backbone.Mediator.publish 'edit-level-component', original: @data.original, majorVersion: @data.majorVersion
