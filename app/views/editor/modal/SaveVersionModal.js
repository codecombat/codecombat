// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let SaveVersionModal;
require('app/styles/modal/save-version-modal.sass');
const ModalView = require('views/core/ModalView');
const template = require('app/templates/editor/modal/save-version-modal');
const DeltaView = require('views/editor/DeltaView');
const Patch = require('models/Patch');
const forms = require('core/forms');
const modelDeltas = require('lib/modelDeltas');

module.exports = (SaveVersionModal = (function() {
  SaveVersionModal = class SaveVersionModal extends ModalView {
    static initClass() {
      this.prototype.id = 'save-version-modal';
      this.prototype.template = template;
      this.prototype.plain = true;
      this.prototype.modalWidthPercent = 60;

      this.prototype.events = {
        'click #save-version-button': 'saveChanges',
        'click #cla-link': 'onClickCLALink',
        'click #agreement-button': 'onAgreedToCLA',
        'click #submit-patch-button': 'submitPatch',
        'submit form': 'onSubmitForm'
      };
    }

    constructor(options) {
      super(options);
      this.onAgreeSucceeded = this.onAgreeSucceeded.bind(this);
      this.onAgreeFailed = this.onAgreeFailed.bind(this);
      this.model = options.model || options.level;
      this.isPatch = !this.model.hasWriteAccess();
      this.hasChanges = this.model.hasLocalChanges();
      if (options.commitMessage) {
        this.commitMessage = options.commitMessage;
      }
    }

    afterRender(insertDeltaView) {
      if (insertDeltaView == null) { insertDeltaView = true; }
      super.afterRender();
      this.$el.find(me.get('signedCLA') ? '#accept-cla-wrapper' : '#save-version-button').hide();
      const changeEl = this.$el.find('.changes-stub');
      if (insertDeltaView) {
        try {
          const deltaView = new DeltaView({model: this.model});
          this.insertSubView(deltaView, changeEl);
        } catch (e) {
          console.error('Couldn\'t create delta view:', e, e.stack);
        }
      }
      if (this.commitMessage) {
        return this.$el.find('.commit-message input').attr('placeholder', $.i18n.t('general.commit_msg')).val(this.commitMessage);
      } else {
        return this.$el.find('.commit-message input').attr('placeholder', $.i18n.t('general.commit_msg'));
      }
    }

    onSubmitForm(e) {
      e.preventDefault();
      if (this.isPatch) { return this.submitPatch(); } else { return this.saveChanges(); }
    }

    saveChanges() {
      return this.trigger('save-new-version', {
        major: this.$el.find('#major-version').prop('checked'),
        commitMessage: this.$el.find('#commit-message').val()
      });
    }

    submitPatch() {
      this.savingPatchError = false;
      forms.clearFormAlerts(this.$el);
      const patch = new Patch();
      patch.set('delta', modelDeltas.getDelta(this.model));
      patch.set('commitMessage', this.$el.find('#commit-message').val());
      patch.set('target', {
        'collection': _.string.underscored(this.model.constructor.className),
        'id': this.model.id
      });
      const errors = patch.validate();
      if (errors) { forms.applyErrorsToForm(this.$el, errors); }
      const res = patch.save();
      if (!res) { return; }
      this.enableModalInProgress(this.$el);

      res.error(jqxhr => {
        this.disableModalInProgress(this.$el);
        this.savingPatchError = (jqxhr.responseJSON != null ? jqxhr.responseJSON.message : undefined) || 'Unknown error.';
        return this.renderSelectors('.save-error-area');
      });

      return res.success(() => {
        return this.hide();
      });
    }

    onClickCLALink() {
      return window.open('/cla', 'cla', 'height=800,width=900');
    }

    onAgreedToCLA() {
      this.$el.find('#agreement-button').text('Saving').prop('disabled', true);
      return $.ajax({
        url: '/db/user/me/agreeToCLA',
        method: 'POST',
        success: this.onAgreeSucceeded,
        error: this.onAgreeFailed
      });
    }

    onAgreeSucceeded() {
      this.$el.find('#agreement-button').text('Thanks!');
      return this.$el.find('#save-version-button').show();
    }

    onAgreeFailed() {
      return this.$el.find('#agreement-button').text('Failed').prop('disabled', false);
    }
  };
  SaveVersionModal.initClass();
  return SaveVersionModal;
})());
