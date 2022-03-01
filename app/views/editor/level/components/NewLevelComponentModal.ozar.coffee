require('app/styles/editor/level/component/new.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/editor/level/component/new'
LevelComponent = require 'models/LevelComponent'
forms = require 'core/forms'
{me} = require 'core/auth'

module.exports = class NewLevelComponentModal extends ModalView
  id: 'editor-level-component-new-modal'
  template: template
  instant: false
  modalWidthPercent: 60

  events:
    'click #new-level-component-submit': 'makeNewLevelComponent'
    'submit form': 'makeNewLevelComponent'

  constructor: (options) ->
    super options
    @systems = LevelComponent.schema.properties.system.enum

  makeNewLevelComponent: (e) ->
    e.preventDefault()
    system = @$el.find('#level-component-system').val()
    name = @$el.find('#level-component-name').val()
    component = new LevelComponent()
    component.set 'system', system
    component.set 'name', name
    component.set 'code', component.get('code', true).replace(/AttacksSelf/g, name)
    component.set 'permissions', [{access: 'owner', target: me.id}]  # Private until saved in a published Level
    res = component.save(null, {type: 'POST'})  # Override PUT so we can trigger postFirstVersion logic
    return unless res

    @showLoading()
    res.error =>
      @hideLoading()
      console.log 'Got errors:', JSON.parse(res.responseText)
      forms.applyErrorsToForm(@$el, JSON.parse(res.responseText))
    res.success =>
      @supermodel.registerModel component
      @hide()
