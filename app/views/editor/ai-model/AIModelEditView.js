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
let AIModelEditView;
require('app/styles/editor/ai-model/edit.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/editor/ai-model/edit');
const AIModel = require('models/AIModel');
const ConfirmModal = require('views/core/ConfirmModal');
const PatchesView = require('views/editor/PatchesView');
const errors = require('core/errors');

require('lib/game-libraries');
require('lib/setupTreema');
const treemaExt = require('core/treema-ext');

module.exports = (AIModelEditView = (function() {
  AIModelEditView = class AIModelEditView extends RootView {
    static initClass() {
      this.prototype.id = 'editor-ai-model-edit-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click #save-button': 'onClickSaveButton',
        'click #delete-button': 'confirmDeletion'
      };
    }

    constructor(options, modelID) {
      super(options);
      this.deleteAIModel = this.deleteAIModel.bind(this);
      this.modelID = modelID;
      this.model = new AIModel({_id: this.modelID});
      this.model.saveBackups = true;
      this.supermodel.loadModel(this.model);
    }

    onLoaded() {
      super.onLoaded();
      this.buildTreema();
      return this.listenTo(this.model, 'change', () => {
        return this.treema.set('/', this.model.attributes);
      });
    }

    buildTreema() {
      if ((this.treema != null) || (!this.model.loaded)) { return; }
      const data = $.extend(true, {}, this.model.attributes);
      const options = {
        data,
        filePath: `db/ai_model/${this.model.get('_id')}`,
        schema: AIModel.schema,
        readOnly: me.get('anonymous'),
        supermodel: this.supermodel
      };
      this.treema = this.$el.find('#ai-model-treema').treema(options);
      this.treema.build();
      return this.treema.open(2);
    }

    afterRender() {
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
    }

    onClickSaveButton(e) {
      this.treema.endExistingEdits();
      for (var key in this.treema.data) {
        var value = this.treema.data[key];
        this.model.set(key, value);
      }

      const res = this.model.save();

      res.error((collection, response, options) => {
        return console.error(response);
      });

      return res.success(() => {
        const url = `/editor/ai-model/${this.model.get('slug') || this.model.id}`;
        return document.location.href = url;
      });
    }

    confirmDeletion() {
      const renderData = {
        title: 'Are you really sure?',
        body: 'This will completely delete the model.',
        decline: 'Not really',
        confirm: 'Definitely'
      };

      const confirmModal = new ConfirmModal(renderData);
      confirmModal.on('confirm', this.deleteAIModel);
      return this.openModalView(confirmModal);
    }

    deleteAIModel() {
      return $.ajax({
        type: 'DELETE',
        success() {
          noty({
            timeout: 5000,
            text: 'Aaaand it\'s gone.',
            type: 'success',
            layout: 'topCenter'
          });
          return _.delay(() => application.router.navigate('/editor/ai-model', {trigger: true})
          , 500);
        },
        error(jqXHR, status, error) {
          console.error(jqXHR);
          return {
            timeout: 5000,
            text: `Deleting model message failed with error code ${jqXHR.status}`,
            type: 'error',
            layout: 'topCenter'
          };
        },
        url: `/db/ai_model/${this.model.id}`
      });
    }
  };
  AIModelEditView.initClass();
  return AIModelEditView;
})());
