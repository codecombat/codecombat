View = require 'views/kinds/ModalView'
template = require 'templates/editor/level/fork'
forms = require 'lib/forms'
Level = require 'models/Level'

module.exports = class LevelForkView extends View
  id: 'editor-level-fork-modal'
  template: template
  instant: false
  modalWidthPercent: 60

  events:
    'click #fork-level-confirm-button': 'forkLevel'
    'submit form': 'forkLevel'

  constructor: (options) ->
    super options
    @level = options.level

  getRenderData: (context={}) ->
    context = super(context)
    context.level = @level
    context

  forkLevel: ->
    @showLoading()
    forms.clearFormAlerts(@$el)
    newLevel = new Level($.extend(true, {}, @level.attributes))
    newLevel.unset '_id'
    newLevel.unset 'version'
    newLevel.unset 'creator'
    newLevel.unset 'created'
    newLevel.unset 'original'
    newLevel.unset 'parent'
    newLevel.set 'commitMessage', "Forked from #{@level.get('name')}"
    newLevel.set 'name', @$el.find('#level-name').val()
    newLevel.set 'permissions', [access: 'owner', target: me.id]
    res = newLevel.save()
    return unless res
    res.error =>
      @hideLoading()
      forms.applyErrorsToForm(@$el.find('form'), JSON.parse(res.responseText))
    res.success =>
      @hide()
      application.router.navigate('editor/level/' + newLevel.get('slug'), {trigger: true})
