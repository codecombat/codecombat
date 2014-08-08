ModalView = require 'views/kinds/ModalView'
template = require 'templates/modal/new_model'
forms = require 'lib/forms'

module.exports = class NewModelModal extends ModalView
  id: 'new-model-modal'
  template: template
  plain: false

  events:
    'click button.new-model-submit': 'onModelSubmitted'
    'submit form': 'onModelSubmitted'

  constructor: (options) ->
    super options
    @model = options.model
    @modelLabel = options.modelLabel
    @properties = options.properties
    $('#name').ready @focusOnName

  getRenderData: ->
    c = super()
    c.modelLabel = @modelLabel
    #c.newModelTitle = @newModelTitle
    c

  makeNewModel: ->
    model = new @model
    name = @$el.find('#name').val()
    model.set('name', name)
    if @model.schema.properties.permissions
      model.set 'permissions', [{access: 'owner', target: me.id}]
    model.set(key, prop) for key, prop of @properties if @properties?
    model

  onModelSubmitted: (e) ->
    e.preventDefault()
    model = @makeNewModel()
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
      @trigger 'model-created', model
      #Backbone.Mediator.publish 'model-save-success', model

  focusOnName: (e) ->
    $('#name').focus() # TODO Why isn't this working anymore.. It does get called
