ModalView = require 'views/core/ModalView'
template = require 'templates/editor/campaign/save-campaign-modal'
DeltaView = require 'views/editor/DeltaView'

module.exports = class SaveCampaignModal extends ModalView
  id: 'save-campaign-modal'
  template: template
  plain: true

  events:
    'click #save-button': 'onClickSaveButton'

  constructor: (options, @modelsToSave) ->
    super(options)

  afterRender: ->
    @$el.find('.delta-view').each((i, el) =>
      $el = $(el)
      model = @modelsToSave.find( id: $el.data('model-id'))
      deltaView = new DeltaView({model: model})
      @insertSubView(deltaView, $el)
    )
    super()

  onClickSaveButton: ->
    @showLoading()
    modelsBeingSaved = (model.patch() for model in @modelsToSave.models)
    $.when(_.compact(modelsBeingSaved)...).done(-> document.location.reload())
