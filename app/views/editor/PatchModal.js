// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let PatchModal;
require('app/styles/editor/patch.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/editor/patch_modal');
const DeltaView = require('views/editor/DeltaView');
const auth = require('core/auth');
const deltasLib = require('core/deltas');
const modelDeltas = require('lib/modelDeltas');

module.exports = (PatchModal = (function() {
  PatchModal = class PatchModal extends ModalView {
    static initClass() {
      this.prototype.id = 'patch-modal';
      this.prototype.template = template;
      this.prototype.plain = true;
      this.prototype.modalWidthPercent = 60;
      this.prototype.instant = true;

      this.prototype.events = {
        'click #withdraw-button': 'withdrawPatch',
        'click #reject-button': 'rejectPatch',
        'click #accept-button': 'onAcceptPatch',
        'click #accept-save-button': 'onAcceptAndSavePatch'
      };

      this.prototype.shortcuts = {
        'a, shift+a': 'acceptPatch',
        'r': 'rejectPatch'
      };
    }

    constructor(patch, targetModel, options) {
      super(options);
      this.patch = patch;
      this.targetModel = targetModel;
      const targetID = this.patch.get('target').id;
      if (targetID === this.targetModel.id) {
        this.originalSource = this.targetModel.clone(false);
      } else {
        this.originalSource = new this.targetModel.constructor({_id:targetID});
        this.supermodel.loadModel(this.originalSource);
      }
    }

    applyDelta() {
      this.headModel = null;
      if (this.targetModel.hasWriteAccess()) {
        this.headModel = this.originalSource.clone(false);
        this.headModel.markToRevert(true);
        this.headModel.set(this.targetModel.attributes);
        this.headModel.loaded = true;
      }

      this.pendingModel = this.originalSource.clone(false);
      this.pendingModel.markToRevert(true);
      this.deltaWorked = modelDeltas.applyDelta(this.pendingModel, this.patch.get('delta'));
      return this.pendingModel.loaded = true;
    }

    render() {
      if (this.supermodel.finished()) { this.applyDelta(); }
      return super.render();
    }

    getRenderData() {
      const c = super.getRenderData();
      c.isPatchCreator = this.patch.get('creator') === auth.me.id;
      c.isPatchRecipient = this.targetModel.hasWriteAccess();
      c.isLevel = __guard__(this.patch.get("target"), x => x.collection) === "level";
      c.status = this.patch.get('status');
      c.patch = this.patch;
      c.deltaWorked = this.deltaWorked;
      return c;
    }

    afterRender() {
      if (!this.supermodel.finished() || !this.deltaWorked) { return super.afterRender(); }
      this.deltaView = new DeltaView({model:this.pendingModel, headModel:this.headModel, skipPaths: deltasLib.DOC_SKIP_PATHS});
      const changeEl = this.$el.find('.changes-stub');
      this.insertSubView(this.deltaView, changeEl);
      return super.afterRender();
    }

    onAcceptPatch() {
      return this.acceptPatch(false);
    }

    onAcceptAndSavePatch() {
      const commitMessage = this.patch.get("commitMessage") || "";
      return this.acceptPatch(true, commitMessage);
    }

    acceptPatch(save, commitMessage) {
      if (save == null) { save = false; }
      const delta = this.deltaView.getApplicableDelta();
      modelDeltas.applyDelta(this.targetModel, delta);
      this.targetModel.saveBackupNow();
      this.patch.setStatus('accepted');
      this.trigger('accepted-patch', {save, commitMessage});
      return this.hide();
    }

    rejectPatch() {
      this.patch.setStatus('rejected');
      return this.hide();
    }

    withdrawPatch() {
      this.patch.setStatus('withdrawn');
      return this.hide();
    }
  };
  PatchModal.initClass();
  return PatchModal;
})());

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}