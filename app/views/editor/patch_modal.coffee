ModalView = require 'views/kinds/ModalView'
template = require 'templates/editor/patch_modal'
DeltaView = require 'views/editor/delta'
auth = require 'lib/auth'

module.exports = class PatchModal extends ModalView
  id: "patch-modal"
  template: template
  plain: true
  modalWidthPercent: 60
  
  events:
    'click #withdraw-button': 'withdrawPatch'
    'click #reject-button': 'rejectPatch'
    'click #accept-button': 'acceptPatch'

  constructor: (@patch, @targetModel, options) ->
    super(options)
    targetID = @patch.get('target').id
    if targetID is @targetModel.id
      @originalSource = @targetModel.clone(false)
    else
      @originalSource = new @targetModel.constructor({_id:targetID})
      @supermodel.loadModel @originalSource, 'source_document'
      
  getRenderData: ->
    c = super()
    c.isPatchCreator = @patch.get('creator') is auth.me.id
    c.isPatchRecipient = @targetModel.hasWriteAccess()
    c.status = @patch.get 'status'
    c.patch = @patch
    c
    
  afterRender: ->
    return unless @supermodel.finished()
    headModel = null
    if @targetModel.hasWriteAccess()
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
    @targetModel.applyDelta(delta)
    @patch.setStatus('accepted')
    @trigger 'accepted-patch'
    @hide()
    
  rejectPatch: ->
    @patch.setStatus('rejected')
    @hide()
    
  withdrawPatch: ->
    @patch.setStatus('withdrawn')
    @hide()