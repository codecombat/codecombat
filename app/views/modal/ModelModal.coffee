require('app/styles/modal/model-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/modal/model-modal'
require 'lib/setupTreema'

module.exports = class ModelModal extends ModalView
  id: 'model-modal'
  template: template
  plain: true

  events: 'click .save-model': 'onSaveModel'

  constructor: (options) ->
    super options
    @models = options.models
    for model in @models when not model.loaded
      @supermodel.loadModel model
      model.fetch cache: false

  afterRender: ->
    return unless @supermodel.finished()
    @modelTreemas = {}
    for model in @models
      data = $.extend true, {}, model.attributes
      schema = $.extend true, {}, model.schema()
      treemaOptions =
        schema: schema
        data: data
        readOnly: false
      modelTreema = @$el.find(".model-treema[data-model-id='#{model.id}']").treema treemaOptions
      modelTreema?.build()
      modelTreema?.open()
      @openTastyTreemas modelTreema, model
      @modelTreemas[model.id] = modelTreema

  openTastyTreemas: (modelTreema, model) ->
    # To save on quick inspection, let's auto-open the properties we're most likely to want to see.
    delicacies = ['code']
    for dish in delicacies
      child = modelTreema.childrenTreemas[dish]
      child?.open()
      if child and dish is 'code' and model.type() is 'LevelSession' and team = modelTreema.get('team')
        desserts = {
          humans: ['programmable-tharin', 'programmable-librarian']
          ogres: ['programmable-brawler', 'programmable-shaman']
        }[team]
        for dessert in desserts
          child.childrenTreemas[dessert]?.open()

  onSaveModel: (e) ->
    container = $(e.target).closest('.model-container')
    model = _.find @models, id: container.data('model-id')
    treema = @modelTreemas[model.id]
    for key, val of treema.data when not _.isEqual val, model.get key
      console.log 'Updating', key, 'from', model.get(key), 'to', val
      model.set key, val
    for key, val of model.attributes when treema.get(key) is undefined and not _.string.startsWith key, '_'
      console.log 'Deleting', key, 'which was', val, 'but man, that ain\'t going to work, now is it?'
      #model.unset key
    if errors = model.validate()
      return console.warn model, 'failed validation with errors:', errors
    return unless res = model.patch()
    res.error =>
      return if @destroyed
      console.error model, 'failed to save with error:', res.responseText
    res.success (model, response, options) =>
      return if @destroyed
      @hide()

  destroy: ->
    @modelTreemas[model].destroy() for model of @modelTreemas
    super()
