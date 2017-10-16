require('app/styles/editor/level/components_tab.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/editor/level/components_tab'
ThangType = require 'models/ThangType'
LevelComponent = require 'models/LevelComponent'
LevelComponentEditView = require './LevelComponentEditView'
LevelComponentNewView = require './NewLevelComponentModal'
require 'lib/setupTreema'

class LevelComponentCollection extends Backbone.Collection
  url: '/db/level.component'
  model: LevelComponent

module.exports = class ComponentsTabView extends CocoView
  id: 'editor-level-components-tab-view'
  template: template
  className: 'tab-pane'

  subscriptions:
    'editor:level-component-editing-ended': 'onLevelComponentEditingEnded'

  events:
    'click #create-new-component-button': 'createNewLevelComponent'
    'click #create-new-component-button-no-select': 'createNewLevelComponent'

  onLoaded: ->

  refreshLevelThangsTreema: (thangsData) ->
    presentComponents = {}
    for thang in thangsData
      componentMap = {}
      thangType = @supermodel.getModelByOriginal ThangType, thang.thangType
      for component in thangType.get('components') ? []
        componentMap[component.original] = component

      for component in thang.components
        componentMap[component.original] = component

      for component in _.values(componentMap)
        haveThisComponent = (presentComponents[component.original + '.' + (component.majorVersion ? 0)] ?= [])
        haveThisComponent.push thang.id if haveThisComponent.length < 100  # for performance when adding many Thangs
    return if _.isEqual presentComponents, @presentComponents
    @presentComponents = presentComponents

    componentModels = @supermodel.getModels LevelComponent
    componentModelMap = {}
    componentModelMap[comp.get('original')] = comp for comp in componentModels
    components = ({original: key.split('.')[0], majorVersion: parseInt(key.split('.')[1], 10), thangs: value, count: value.length} for key, value of @presentComponents)
    components = components.concat ({original: c.get('original'), majorVersion: c.get('version').major, thangs: [], count: 0} for c in componentModels when not @presentComponents[c.get('original') + '.' + c.get('version').major])
    treemaData = _.sortBy components, (comp) =>
      component = componentModelMap[comp.original]
      res = [(if comp.count then 0 else 1), component.get('system'), component.get('name')]
      return res

    res = {}
    res[treemaData[key].original] = treemaData[key] for key in [0 ... treemaData.length]
    treemaData = (value for key, value of res)  # Removing duplicates from treemaData

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
    Backbone.Mediator.publish 'editor:view-switched', {}

  editLevelComponent: (e) ->
    @levelComponentEditView = @insertSubView new LevelComponentEditView(original: e.original, majorVersion: e.majorVersion, supermodel: @supermodel)

  onLevelComponentEditingEnded: (e) ->
    @removeSubView @levelComponentEditView
    @levelComponentEditView = null

  destroy: ->
    @componentsTreema?.destroy()
    super()

class LevelComponentNode extends TreemaObjectNode
  valueClass: 'treema-level-component'
  collection: false
  buildValueForDisplay: (valEl, data) ->
    count = if data.count is 1 then data.thangs[0] else ((if data.count >= 100 then '100+' else data.count) + ' Thangs')
    if data.original.match ':'
      name = 'Old: ' + data.original.replace('systems/', '')
    else
      comp = _.find @settings.supermodel.getModels(LevelComponent), (m) =>
        m.get('original') is data.original and m.get('version').major is data.majorVersion
      name = "#{comp.get('system')}.#{comp.get('name')} v#{comp.get('version').major}"
    result = @buildValueForDisplaySimply valEl, "#{name} (#{count})"
    result.addClass 'not-present' unless data.count
    result
