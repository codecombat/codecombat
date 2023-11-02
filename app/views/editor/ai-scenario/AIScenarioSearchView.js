// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AIScenarioSearchView;
require('app/styles/editor/ai-scenario/table.sass');
const SearchView = require('views/common/SearchView');

module.exports = (AIScenarioSearchView = (function() {
  AIScenarioSearchView = class AIScenarioSearchView extends SearchView {
    static initClass() {
      this.prototype.id = 'editor-ai-scenario-home-view';
      this.prototype.modelLabel = 'Scenario';
      this.prototype.model = require('models/AIScenario');
      this.prototype.modelURL = '/db/ai_scenario';
      this.prototype.tableTemplate = require('app/templates/editor/ai-scenario/table');
      this.prototype.projection = ['name', 'slug', 'description', 'mode', 'tool', 'task','doc', 'releasePhase', 'initialActionQueue', 'i18n'];
      this.prototype.page = 'ai-scenario';
      this.prototype.canMakeNew = true;
  
      this.prototype.events =
        {'click #delete-button': 'deleteAIScenario'};
    }

    getRenderData() {
      const context = super.getRenderData();
      context.currentEditor = 'editor.ai_scenario_title';
      context.currentNew = 'editor.new_ai_scenario_title';
      context.currentNewSignup = 'editor.new_ai_scenario_title_login';
      context.currentSearch = 'editor.ai_scenario_search_title';
      this.$el.i18n();
      this.applyRTLIfNeeded();
      return context;
    }

    deleteAIScenario(e) {
      const scenarioId = $(e.target).parents('tr').data('scenario');
      const scenarioName = $(e.target).parents('tr').data('name');
      if (!window.confirm(`Really delete scenario ${scenarioName}?`)) {
        noty({text: 'Cancelled', timeout: 1000});
        return;
      }
      this.$el.find(`tr[data-scenario='${scenarioId}']`).remove();
      return $.ajax({
        type: 'DELETE',
        success() {
          return noty({
            timeout: 2000,
            text: 'Aaaand it\'s gone.',
            type: 'success',
            layout: 'topCenter'
          });
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
        url: `/db/ai_scenario/${scenarioId}`
      });
    }
  };
  AIScenarioSearchView.initClass();
  return AIScenarioSearchView;
})());
