// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ForkModal;
const ModalView = require('views/core/ModalView');
const template = require('app/templates/editor/fork-modal');
const forms = require('core/forms');
const utils = require('core/utils');

module.exports = (ForkModal = (function() {
  ForkModal = class ForkModal extends ModalView {
    static initClass() {
      this.prototype.id = 'fork-modal';
      this.prototype.template = template;
      this.prototype.instant = false;
  
      this.prototype.events = {
        'click #fork-model-confirm-button': 'forkModel',
        'submit form': 'forkModel'
      };
    }

    constructor(options) {
      super(options);
      this.editorPath = options.editorPath;  // like 'level' or 'thang'
      this.model = options.model;
      this.modelClass = this.model.constructor;
    }

    forkModel(e) {
      e.preventDefault();
      this.showLoading();
      forms.clearFormAlerts(this.$el);
      const newModel = new this.modelClass($.extend(true, {}, this.model.attributes));
      newModel.unset('_id');
      newModel.unset('version');
      newModel.unset('creator');
      newModel.unset('created');
      newModel.unset('original');
      newModel.unset('parent');
      newModel.unset('i18n');
      newModel.unset('i18nCoverage');
      if (utils.isOzaria) {
        newModel.unset('tasks');
      }
      newModel.set('commitMessage', `Forked from ${this.model.get('name')}`);
      newModel.set('name', this.$el.find('#fork-model-name').val());
      if (utils.isCodeCombat && newModel.get('tasks')) {
        newModel.set('tasks', newModel.get('tasks').map(task => ({
          name: task.name,
          complete: false
        })));
      }
      if (this.model.schema().properties.permissions) {
        newModel.set('permissions', [{access: 'owner', target: me.id}]);
      }
      const newPathPrefix = `editor/${this.editorPath}/`;
      const res = newModel.save(null, {type: 'POST'});  // Override PUT so we can trigger postFirstVersion logic
      if (!res) { return; }
      res.error(() => {
        this.hideLoading();
        return forms.applyErrorsToForm(this.$el.find('form'), JSON.parse(res.responseText));
      });
      return res.success(() => {
        this.hide();
        return application.router.navigate(newPathPrefix + newModel.get('slug'), {trigger: true});
      });
    }
  };
  ForkModal.initClass();
  return ForkModal;
})());
