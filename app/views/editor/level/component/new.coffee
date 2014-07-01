View = require 'views/kinds/ModalView'
template = require 'templates/editor/level/component/new'
LevelComponent = require 'models/LevelComponent'
forms = require 'lib/forms'
{me} = require 'lib/auth'

module.exports = class LevelComponentNewView extends View
  id: 'editor-level-component-new-modal'
  template: template
  instant: false
  modalWidthPercent: 60

  events:
    'click #new-level-component-submit': 'makeNewLevelComponent'
    'submit form': 'makeNewLevelComponent'

  makeNewLevelComponent: (e) ->
    e.preventDefault()
    system = @$el.find('#level-component-system').val()
    name = @$el.find('#level-component-name').val()
    component = new LevelComponent()
    component.set 'system', system
    component.set 'name', name
    component.set 'code', component.get('code').replace(/AttacksSelf/g, name)
    component.set 'permissions', [{access: 'owner', target: me.id}]  # Private until saved in a published Level
    res = component.save()
    return unless res

    @showLoading()
    res.error =>
      @hideLoading()
      console.log 'Got errors:', JSON.parse(res.responseText)
      forms.applyErrorsToForm(@$el, JSON.parse(res.responseText))
    res.success =>
      @supermodel.registerModel component
      Backbone.Mediator.publish 'edit-level-component', original: component.get('_id'), majorVersion: 0
      @hide()
