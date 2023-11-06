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
let AIProjectEditView;
require('app/styles/editor/ai-project/edit.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/editor/ai-project/edit');
const AIProject = require('models/AIProject');
const ConfirmModal = require('views/core/ConfirmModal');
const PatchesView = require('views/editor/PatchesView');
const errors = require('core/errors');

const nodes = require('views/editor/level/treema_nodes');

require('lib/game-libraries');
require('lib/setupTreema');
const treemaExt = require('core/treema-ext');

module.exports = (AIProjectEditView = (function() {
  AIProjectEditView = class AIProjectEditView extends RootView {
    static initClass() {
      this.prototype.id = 'editor-ai-project-edit-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click #save-button': 'onClickSaveButton',
        'click #delete-button': 'confirmDeletion'
      };
    }

    constructor(options, projectID) {
      super(options);
      this.deleteAIProject = this.deleteAIProject.bind(this);
      this.projectID = projectID;
      this.project = new AIProject({_id: this.projectID});
      this.project.saveBackups = true;
      this.supermodel.loadModel(this.project);
    }

    onLoaded() {
      super.onLoaded();
      this.buildTreema();
      return this.listenTo(this.project, 'change', () => {
        return this.treema.set('/', this.project.attributes);
      });
    }

    buildTreema() {
      if ((this.treema != null) || (!this.project.loaded)) { return; }
      const data = $.extend(true, {}, this.project.attributes);
      const options = {
        data,
        filePath: `db/ai_project/${this.project.get('_id')}`,
        schema: AIProject.schema,
        readOnly: me.get('anonymous'),
        supermodel: this.supermodel,
        nodeClasses: {
          'chat-message-link': nodes.ChatMessageLinkNode
        }
      };
      this.treema = this.$el.find('#ai-project-treema').treema(options);
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
        this.project.set(key, value);
      }

      const res = this.project.save();

      res.error((collection, response, options) => {
        return console.error(response);
      });

      return res.success(() => {
        const url = `/editor/ai-project/${this.project.get('slug') || this.project.id}`;
        return document.location.href = url;
      });
    }

    confirmDeletion() {
      const renderData = {
        title: 'Are you really sure?',
        body: 'This will completely delete the project.',
        decline: 'Not really',
        confirm: 'Definitely'
      };

      const confirmModal = new ConfirmModal(renderData);
      confirmModal.on('confirm', this.deleteAIProject);
      return this.openModalView(confirmModal);
    }

    deleteAIProject() {
      return $.ajax({
        type: 'DELETE',
        success() {
          noty({
            timeout: 5000,
            text: 'Aaaand it\'s gone.',
            type: 'success',
            layout: 'topCenter'
          });
          return _.delay(() => application.router.navigate('/editor/ai-project', {trigger: true})
          , 500);
        },
        error(jqXHR, status, error) {
          console.error(jqXHR);
          return {
            timeout: 5000,
            text: `Deleting project message failed with error code ${jqXHR.status}`,
            type: 'error',
            layout: 'topCenter'
          };
        },
        url: `/db/ai_project/${this.project.id}`
      });
    }
  };
  AIProjectEditView.initClass();
  return AIProjectEditView;
})());
