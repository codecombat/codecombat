ModalView = require 'views/core/ModalView'
template = require 'templates/editor/modal/new-model-modal'
forms = require 'core/forms'

module.exports = class NewModelModal extends ModalView
  id: 'new-model-modal'
  template: template
  plain: false

  events:
    'click button.new-model-submit': 'onModelSubmitted'
    'submit form': 'onModelSubmitted'

  constructor: (options) ->
    super options
    @modelClass = options.model
    @modelLabel = options.modelLabel
    @newModelTitle = "editor.new_#{_.string.slugify @modelLabel}_title"
    @properties = options.properties

  makeNewModel: ->
    model = new @modelClass
    name = @$el.find('#name').val()
    model.set('name', name)
    if @modelClass.name is 'Level'
      model.set('tasks', @modelClass.schema.default.tasks)
    if model.schema().properties.permissions
      model.set 'permissions', [{access: 'owner', target: me.id}]
    model.set(key, prop) for key, prop of @properties if @properties?
    model

  onModelSubmitted: (e) ->
    e.preventDefault()
    model = @makeNewModel()
    res = model.save(null, {type: 'POST'})  # Override PUT so we can trigger postFirstVersion logic if needed
    return unless res

    forms.clearFormAlerts @$el
    @showLoading(@$el.find('.modal-body'))
    res.error =>
      @hideLoading()
      forms.applyErrorsToForm(@$el, JSON.parse(res.responseText))
      #Backbone.Mediator.publish 'model-save-fail', model
    res.success =>
      @$el.modal('hide')
      @trigger 'model-created', model
      #Backbone.Mediator.publish 'model-save-success', model

  afterInsert: ->
    super()
    _.delay (=> @$el?.find('#name').focus()), 500
