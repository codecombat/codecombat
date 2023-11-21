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
let AIScenarioEditView;
require('app/styles/editor/ai-scenario/edit.sass');
const RootView = require('views/core/RootView');
const template = require('app/templates/editor/ai-scenario/edit');
const AIScenario = require('models/AIScenario');
const ConfirmModal = require('views/core/ConfirmModal');
const PatchesView = require('views/editor/PatchesView');
const errors = require('core/errors');

const nodes = require('views/editor/level/treema_nodes');

require('lib/game-libraries');
require('lib/setupTreema');
const treemaExt = require('core/treema-ext');

module.exports = (AIScenarioEditView = (function() {
  AIScenarioEditView = class AIScenarioEditView extends RootView {
    static initClass() {
      this.prototype.id = 'editor-ai-scenario-edit-view';
      this.prototype.template = template;

      this.prototype.events = {
        'click #save-button': 'onClickSaveButton',
        'click #i18n-button': 'onPopulateI18N',
        'click #delete-button': 'confirmDeletion',
        'click #fix-button': 'onFix',
        'click #diff-button': 'onAddDiff'
      };
    }

    constructor(options, scenarioID) {
      super(options);
      this.deleteAIScenario = this.deleteAIScenario.bind(this);
      this.scenarioID = scenarioID;
      this.scenario = new AIScenario({_id: this.scenarioID});
      this.scenario.saveBackups = true;
      this.supermodel.loadModel(this.scenario);
    }

    onLoaded() {
      super.onLoaded();
      this.buildTreema();
      return this.listenTo(this.scenario, 'change', () => {
        this.scenario.updateI18NCoverage();
        return this.treema.set('/', this.scenario.attributes);
      });
    }

    buildTreema() {
      if ((this.treema != null) || (!this.scenario.loaded)) { return; }
      const data = $.extend(true, {}, this.scenario.attributes);
      const options = {
        data,
        filePath: `db/ai_scenario/${this.scenario.get('_id')}`,
        schema: AIScenario.schema,
        readOnly: me.get('anonymous'),
        supermodel: this.supermodel,
        nodeClasses: {
          'chat-message-link': nodes.ChatMessageLinkNode
        }
      };
      this.treema = this.$el.find('#ai-scenario-treema').treema(options);
      this.treema.build();
      return this.treema.open(5);
    }

    afterRender() {
      super.afterRender();
      if (!this.supermodel.finished()) { return; }
    }

    onPopulateI18N() {
      return this.scenario.populateI18N();
    }

    onClickSaveButton(e) {
      this.treema.endExistingEdits();
      for (var key in this.treema.data) {
        var value = this.treema.data[key];
        this.scenario.set(key, value);
      }
      this.scenario.updateI18NCoverage();

      const res = this.scenario.save();

      res.error((collection, response, options) => {
        return console.error(response);
      });

      return res.success(() => {
        const url = `/editor/ai-scenario/${this.scenario.get('slug') || this.scenario.id}`;
        return document.location.href = url;
      });
    }

    confirmDeletion() {
      const renderData = {
        title: 'Are you really sure?',
        body: 'This will completely delete the scenario.',
        decline: 'Not really',
        confirm: 'Definitely'
      };

      const confirmModal = new ConfirmModal(renderData);
      confirmModal.on('confirm', this.deleteAIScenario);
      return this.openModalView(confirmModal);
    }

    deleteAIScenario() {
      return $.ajax({
        type: 'DELETE',
        success() {
          noty({
            timeout: 5000,
            text: 'Aaaand it\'s gone.',
            type: 'success',
            layout: 'topCenter'
          });
          return _.delay(() => application.router.navigate('/editor/ai-scenario', {trigger: true})
          , 500);
        },
        error(jqXHR, status, error) {
          console.error(jqXHR);
          return {
            timeout: 5000,
            text: `Deleting scenario message failed with error code ${jqXHR.status}`,
            type: 'error',
            layout: 'topCenter'
          };
        },
        url: `/db/ai_scenario/${this.scenario.id}`
      });
    }
  };
  AIScenarioEditView.initClass();
  return AIScenarioEditView;
})());
