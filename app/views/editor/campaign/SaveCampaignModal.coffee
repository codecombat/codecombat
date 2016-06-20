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
    @reverseLevelsBeforeSave()
    modelsBeingSaved = (model.patch() for model in @modelsToSave.models)
    $.when(_.compact(modelsBeingSaved)...).done(-> document.location.reload())

  reverseLevelsBeforeSave: ->
    # For some unfathomable reason, not in our code anywhere, the levels get reversed during the save somehow.
    # Since we want to maintain their orders, we reverse them first, so that when they're reversed again, it's right.
    # Yaaaay!
    return unless campaign = _.find @modelsToSave.models, (m) -> m.constructor.className is 'Campaign'
    levelsReversed = {}
    levels = campaign.get 'levels'
    levelIDs = _.keys(levels).reverse()
    for levelID in levelIDs
      levelsReversed[levelID] = levels[levelID]
      campaign.set 'levels', levelsReversed
