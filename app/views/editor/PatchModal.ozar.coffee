require('app/styles/editor/patch.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/editor/patch_modal'
DeltaView = require 'views/editor/DeltaView'
auth = require 'core/auth'
deltasLib = require 'core/deltas'
modelDeltas = require 'lib/modelDeltas'

module.exports = class PatchModal extends ModalView
  id: 'patch-modal'
  template: template
  plain: true
  modalWidthPercent: 60
  instant: true

  events:
    'click #withdraw-button': 'withdrawPatch'
    'click #reject-button': 'rejectPatch'
    'click #accept-button': 'onAcceptPatch'
    'click #accept-save-button': 'onAcceptAndSavePatch'

  shortcuts:
    'a, shift+a': 'acceptPatch'
    'r': 'rejectPatch'

  constructor: (@patch, @targetModel, options) ->
    super(options)
    targetID = @patch.get('target').id
    if targetID is @targetModel.id
      @originalSource = @targetModel.clone(false)
    else
      @originalSource = new @targetModel.constructor({_id:targetID})
      @supermodel.loadModel @originalSource

  applyDelta: ->
    @headModel = null
    if @targetModel.hasWriteAccess()
      @headModel = @originalSource.clone(false)
      @headModel.markToRevert true
      @headModel.set(@targetModel.attributes)
      @headModel.loaded = true

    @pendingModel = @originalSource.clone(false)
    @pendingModel.markToRevert true
    @deltaWorked = modelDeltas.applyDelta(@pendingModel, @patch.get('delta'))
    @pendingModel.loaded = true

  render: ->
    @applyDelta() if @supermodel.finished()
    super()

  getRenderData: ->
    c = super()
    c.isPatchCreator = @patch.get('creator') is auth.me.id
    c.isPatchRecipient = @targetModel.hasWriteAccess()
    c.isLevel = @patch.get("target")?.collection is "level"
    c.status = @patch.get 'status'
    c.patch = @patch
    c.deltaWorked = @deltaWorked
    c

  afterRender: ->
    return super() unless @supermodel.finished() and @deltaWorked
    @deltaView = new DeltaView({model:@pendingModel, headModel:@headModel, skipPaths: deltasLib.DOC_SKIP_PATHS})
    changeEl = @$el.find('.changes-stub')
    @insertSubView(@deltaView, changeEl)
    super()

  onAcceptPatch: ->
    @acceptPatch false

  onAcceptAndSavePatch: ->
    commitMessage = @patch.get("commitMessage") or ""
    @acceptPatch true, commitMessage

  acceptPatch: (save=false, commitMessage) ->
    delta = @deltaView.getApplicableDelta()
    modelDeltas.applyDelta(@targetModel, delta)
    @targetModel.saveBackupNow()
    @patch.setStatus('accepted')
    @trigger 'accepted-patch', {save, commitMessage}
    @hide()

  rejectPatch: ->
    @patch.setStatus('rejected')
    @hide()

  withdrawPatch: ->
    @patch.setStatus('withdrawn')
    @hide()
