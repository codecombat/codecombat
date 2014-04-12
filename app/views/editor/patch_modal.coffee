ModalView = require 'views/kinds/ModalView'
template = require 'templates/editor/patch_modal'
DeltaView = require 'views/editor/delta'

module.exports = class PatchModal extends ModalView
  id: "patch-modal"
  template: template
  plain: true

  constructor: (@patch, @targetModel, options) ->
    super(options)
    targetID = @patch.get('target').id
    if false
      @originalSource = targetModel.clone(false)
      @onOriginalLoaded()
    else
      @originalSource = new targetModel.constructor({_id:targetID})
      @originalSource.fetch()
      @listenToOnce @originalSource, 'sync', @onOriginalLoaded
      @addResourceToLoad(@originalSource)
      
  getRenderData: ->
    c = super()
    c
    
  afterRender: ->
    return if @originalSource.loading
    headModel = @originalSource.clone(false)
    headModel.set(@targetModel.attributes)
    
    pendingModel = @originalSource.clone(false)
    pendingModel.applyDelta(@patch.get('delta'))

    @deltaView = new DeltaView({model:pendingModel, headModel:headModel})
    changeEl = @$el.find('.changes-stub')
    @insertSubView(@deltaView, changeEl)
    super()
    
  acceptPatch: ->
    delta = @deltaView.getApplicableDelta()
    pendingModel = @originalSource.clone(false)
    pendingModel.applyDelta(delta)