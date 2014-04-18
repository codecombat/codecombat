View = require 'views/kinds/ModalView'
template = require 'templates/modal/model'

module.exports = class ModelModal extends View
  id: 'model-modal'
  template: template

  constructor: (options) ->
    super options
    @models = options.models
    for model in @models when not model.loaded
      @addResourceToLoad model, 'model'
      model.fetch()

  getRenderData: ->
    c = super()
    c.models = @models
    c

  afterRender: ->
    super()
    return if @loading()
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
