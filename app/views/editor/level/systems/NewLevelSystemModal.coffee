ModalView = require 'views/core/ModalView'
template = require 'templates/editor/level/system/new'
LevelSystem = require 'models/LevelSystem'
forms = require 'core/forms'
{me} = require 'core/auth'

module.exports = class NewLevelSystemModal extends ModalView
  id: 'editor-level-system-new-modal'
  template: template
  instant: false
  modalWidthPercent: 60

  events:
    'click #new-level-system-submit': 'makeNewLevelSystem'
    'submit form': 'makeNewLevelSystem'

  makeNewLevelSystem: (e) ->
    e.preventDefault()
    system = @$el.find('#level-system-system').val()
    name = @$el.find('#level-system-name').val()
    system = new LevelSystem()
    system.set 'name', name
    system.set 'code', system.get('code', true).replace(/Jitter/g, name)
    system.set 'permissions', [{access: 'owner', target: me.id}]  # Private until saved in a published Level
    res = system.save(null, {type: 'POST'})  # Override PUT so we can trigger postFirstVersion logic
    return unless res

    @showLoading()
    res.error =>
      @hideLoading()
      console.log 'Got errors:', JSON.parse(res.responseText)
      forms.applyErrorsToForm(@$el, JSON.parse(res.responseText))
    res.success =>
      @supermodel.registerModel system
      Backbone.Mediator.publish 'editor:edit-level-system', original: system.get('_id'), majorVersion: 0
      @hide()
