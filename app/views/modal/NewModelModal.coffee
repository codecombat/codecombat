ModalView = require 'views/kinds/ModalView'
template = require 'templates/modal/new_model'
forms = require 'lib/forms'

module.exports = class NewModelModal extends ModalView
  id: 'new-model-modal'
  template: template
  plain: false

  events:
    'click button.new-model-submit': 'makeNewModel'
    'submit form': 'makeNewModel'
    'shown.bs.modal #new-model-modal': 'focusOnName'


  constructor: (options) ->
    super options
    @model = options.model
    @modelLabel = options.modelLabel

  getRenderData: ->
    c = super()
    c.modelLabel = @modelLabel
    #c.newModelTitle = @newModelTitle
    c

  makeNewModel: (e) ->
    e.preventDefault()
    name = @$el.find('#name').val()
    model = new @model
    model.set('name', name)
    if @model.schema.properties.permissions
      model.set 'permissions', [{access: 'owner', target: me.id}]
    res = model.save()
    return unless res

    forms.clearFormAlerts @$el
    @showLoading(@$el.find('.modal-body'))
    res.error =>
      @hideLoading()
      forms.applyErrorsToForm(@$el, JSON.parse(res.responseText))
      #Backbone.Mediator.publish 'model-save-fail', model
    res.success =>
      @$el.modal('hide')
      @trigger 'success', model
      #Backbone.Mediator.publish 'model-save-success', model

